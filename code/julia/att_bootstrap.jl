using DataFrames
using StatsModels
using GLM
using StatsBase
using Random
using NearestNeighbors
using Statistics
using Base.Threads
using CategoricalArrays
using Logging

const DEFAULT_NN_LIST = [1, 2, 3, 4]

# Empty results schema (prevents append! errors)
function empty_results()
    DataFrame(
        outcome = String[],
        treat   = String[],
        nn      = Int[],
        b       = Float64[],
        se      = Float64[],
        lb      = Float64[],
        ub      = Float64[],
    )
end

# Single-draw ATT with k-NN matching
function att_once(sdf::DataFrame, outcome::Symbol, nn::Integer)
    control = sdf[sdf.treat .== false, :]
    treated = sdf[sdf.treat .== true, :]
    if nrow(control) == 0 || nrow(treated) == 0
        return NaN
    end
    tree = KDTree(reshape(control.pr, 1, :))
    diffs = Float64[]
    for row in eachrow(treated)
        k = min(nn, nrow(control))
        idxs = knn(tree, [row.pr], k)[1]
        push!(diffs, row[outcome] - mean(control[!, outcome][idxs]))
    end
    return isempty(diffs) ? NaN : mean(diffs)
end

# Single-draw ATT with k-NN matching, restricting matches within a cluster (e.g., school)
function att_once_within(sdf::DataFrame, outcome::Symbol, nn::Integer, cluster::Symbol)
    atts = Float64[]
    for sch in unique(sdf[!, cluster])
        subsample = sdf[sdf[!, cluster] .== sch, :]
        control = subsample[subsample.treat .== false, :]
        treated = subsample[subsample.treat .== true, :]
        if nrow(control) == 0 || nrow(treated) == 0
            continue
        end
        tree = KDTree(reshape(control.pr, 1, :))
        for row in eachrow(treated)
            k = min(nn, nrow(control))
            idxs = knn(tree, [row.pr], k)[1]
            push!(atts, row[outcome] - mean(control[!, outcome][idxs]))
        end
    end
    return isempty(atts) ? NaN : mean(atts)
end

# Clustered bootstrap ATT for one treatment/outcome
function att_boot(
    df::DataFrame,
    treat_val::Integer,
    outcome::Symbol;
    controls::Vector{Symbol},
    cluster::Symbol = :rbd,
    reps::Int = 100,
    nn_list::Vector{Int} = DEFAULT_NN_LIST,
    seed::Int = 1234,
    label_map::Dict{Int, String} = Dict{Int, String}(),
    within_school::Bool = true,
    pooled_fe::Bool = false,
    fallback_to_pooled::Bool = true,
)
    out = empty_results()
    cis_label = get(label_map, 1, "Cis boys")
    target_label = get(label_map, treat_val, string(treat_val))

    # match on string labels (Stata labeled categorical exports as strings)
    gstr = String.(df.gender)
    sdf0 = df[(gstr .== cis_label) .| (gstr .== target_label), :]
    sdf0.treat = String.(sdf0.gender) .== target_label
    if sum(sdf0.treat) == 0 || sum(.!sdf0.treat) == 0
        return out
    end

    # propensity model
    f = Term(:treat) ~ sum(Term.(controls))
    m = nothing
    try
        if pooled_fe
            sdf0[!, cluster] = categorical(sdf0[!, cluster])
            m = glm(f + Term(cluster), sdf0, Binomial(), LogitLink())
        else
            m = glm(f, sdf0, Binomial(), LogitLink())
        end
    catch err
        if pooled_fe && fallback_to_pooled
            @warn "FE propensity model failed; falling back to pooled model" err
            try
                m = glm(f, sdf0, Binomial(), LogitLink())
            catch err2
                @warn "Pooled propensity model failed; returning empty results" err2
                return out
            end
        else
            @warn "Propensity model failed; returning empty results" err
            return out
        end
    end
    try
        sdf0.pr = predict(m)
    catch err
        @warn "Propensity prediction failed; returning empty results" err
        return out
    end

    clusters = unique(sdf0[!, cluster])

    for nn in nn_list
        atts = fill(NaN, reps)
        Threads.@threads for b in 1:reps
            rng = MersenneTwister(seed + Threads.threadid() * 100000 + b)
            boot = if within_school
                boot_ids = sample(rng, clusters, length(clusters); replace = true)
                reduce(vcat, [sdf0[sdf0[!, cluster] .== cid, :] for cid in boot_ids])
            else
                idxs = sample(rng, 1:nrow(sdf0), nrow(sdf0); replace = true)
                sdf0[idxs, :]
            end
            atts[b] = att_once(boot, outcome, nn)
        end
        vals = filter(!isnan, atts)
        if !isempty(vals)
            m_att = mean(vals)
            se_att = std(vals)
            qs = quantile(vals, [0.025, 0.975])
            tlabel = get(label_map, treat_val, string(treat_val))
            push!(out, (string(outcome), tlabel, nn, m_att, se_att, qs[1], qs[2]))
        end
    end

    return out
end

# Run bootstrap for multiple treatments/outcomes
function att_boot_all(
    df::DataFrame,
    treatments::Vector{Int},
    outcomes::Vector{Symbol},
    controls::Vector{Symbol};
    cluster::Symbol = :rbd,
    reps_map::Dict{Int, Int} = Dict{Int, Int}(),
    default_reps::Int = 100,
    nn_list::Vector{Int} = DEFAULT_NN_LIST,
    seed::Int = 1234,
    label_map::Dict{Int, String} = Dict{Int, String}(),
    within_school::Bool = true,
    pooled_fe::Bool = false,
    fallback_to_pooled::Bool = true,
)
    results = empty_results()
    for outcome in outcomes
        for tr in treatments
            reps = get(reps_map, tr, default_reps)
            res = att_boot(
                df,
                tr,
                outcome;
                controls = controls,
                cluster = cluster,
                reps = reps,
                nn_list = nn_list,
                seed = seed,
                label_map = label_map,
                within_school = within_school,
                pooled_fe = pooled_fe,
                fallback_to_pooled = fallback_to_pooled,
            )
            if nrow(res) > 0
                append!(results, res)
            end
        end
    end
    return results
end

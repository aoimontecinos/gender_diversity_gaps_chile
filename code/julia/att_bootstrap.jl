using DataFrames
using StatsModels
using GLM
using StatsBase
using Random
using NearestNeighbors
using Statistics
using Base.Threads

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
    m = glm(f, sdf0, Binomial(), LogitLink())
    sdf0.pr = predict(m)

    clusters = unique(sdf0[!, cluster])

    for nn in nn_list
        atts = fill(NaN, reps)
        Threads.@threads for b in 1:reps
            rng = MersenneTwister(seed + Threads.threadid() * 100000 + b)
            boot_ids = sample(rng, clusters, length(clusters); replace = true)
            boot = reduce(vcat, [sdf0[sdf0[!, cluster] .== cid, :] for cid in boot_ids])
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
            )
            if nrow(res) > 0
                append!(results, res)
            end
        end
    end
    return results
end

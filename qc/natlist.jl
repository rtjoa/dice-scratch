# Demo of using BDD MLE to learn flip probs for 

using Revise
using Dice

include("inductive.jl")
include("mycudd.jl")

# ==============================================================================
# Flips id'd by arbitrary values
# ==============================================================================

flips = Dict{Any, Dice.Flip}()

function flip_for(x)
    get!(flips, x) do
        flip(0.5)
    end
end

# ==============================================================================
# DistNatList
# ==============================================================================

DistNatList = InductiveDistType()
DistNatList.constructors = [
    ("Nil",  []),
    ("Cons", [DistUInt32, DistNatList]),
]

DistNil()       = construct(DistNatList, "Nil",  ())
DistCons(x, xs) = construct(DistNatList, "Cons", (x, xs))

function probLength(l)
    match(l, [
        "Nil"  => ()      -> DistUInt32(0),
        "Cons" => (x, xs) -> DistUInt32(1) + probLength(xs),
    ])
end


# ==============================================================================
# genList
# ==============================================================================

# returns (list, evidence)
function genList(size, lo=DistUInt32(0))
    if size == 0
        return (DistNil(), true)
    end

    @dice_ite if flip_for(size)
        (DistNil(), true)
    else
        x = DistUInt32(5) #uniform(DistUInt32, 0, hi)
        list, evid = genList(size-1, x)
        DistCons(x, list), (x >= lo) & evid
    end
end


# ==============================================================================
# MLE
# ==============================================================================

function logprob(roots::Vector{CuddNode}, flip_probs::Dict{Any, Float64})
    cache = Dict{CuddNode,Float64}()
    terminal = get_one(roots[1])
    cache[terminal] = log(one(Float64))
    cache[not(terminal)] = log(zero(Float64))

    rec(x) = 
        get!(cache, x) do
            prob = flip_probs[level(x)]
            a = log(prob) + rec(high(x))
            b = log(1.0-prob) + rec(low(x))
            if (!isfinite(a))
                b
            elseif (!isfinite(b))
                a
            else
                # log(exp(a) + exp(y))
                # https://www.wolframalpha.com/input?i=log%28e%5Ex%2Be%5Ey%29+-+%28max%28x%2C+y%29+%2B+log%281+%2B+e%5E%28-%7Cx-y%7C%29%29
                max(a,b) + log1p(exp(-abs(a-b)))
            end
        end
    
    for root in roots
        rec(root)
    end
    cache
end

function grad_logprob(root::CuddNode, flip_probs, logprobs::Dict{CuddNode, Float64})
    grad = zeros(length(flip_probs))
    deriv = Dict{CuddNode, Float64}()
    deriv[root] = 1
    level_traversal(root) do node
        i, lo, hi = level(node), low(node), high(node)
        fhi, flo = logprobs[hi], logprobs[lo]
        denom = flip_probs[i] * exp(fhi) + (1 - flip_probs[i]) * exp(flo)
        get!(deriv, hi, 0)
        get!(deriv, lo, 0)
        deriv[hi] += deriv[node] * flip_probs[i] * exp(fhi) / denom
        deriv[lo] += deriv[node] * (1 - flip_probs[i]) * exp(flo) / denom
        grad[i] += deriv[node] * (exp(fhi) - exp(flo)) / denom
    end
    # println("rev: $(grad)")
    grad
end

function grad_logprob_fwd(root::CuddNode, flip_probs, logprobs)
    cache = Dict{CuddNode,Any}()
    zero_grad = [zero(Float64) for _ in flip_probs]

    rec(x) =
        if is_constant(x)
            zero_grad
        else
            get!(cache, x) do
                i, lo, hi = level(x), low(x), high(x)
                fhi = logprobs[hi]
                flo = logprobs[lo]
                [
                    begin
                        denom = param * exp(fhi) + (1 - param) * exp(flo)
                        if p_i == i
                            (exp(fhi) - exp(flo))/denom
                        else
                            (param * exp(fhi) * rec(hi)[p_i] + (1 - param) * exp(flo) * rec(lo)[p_i])/denom
                        end
                    end
                    for (p_i, param) in enumerate(flip_probs) 
                ]
            end
        end
    
    rec(root)
end

function main()
    empty!(flips)
    size0 = 100
    l8, evid = genList(size0)
    len = probLength(l8)
    println(pr(len))

    dataset = [DistUInt32(x) for x in 0:size0]
    # dataset = [dataset[2]]

    iters = 1

    debug_info_ref = Ref{CuddDebugInfo}()
    qs = [prob_equals(len, x) for x in dataset]
    pr(vcat(qs, values(flips))..., algo=Cudd(debug_info_ref=debug_info_ref))
    ccache = debug_info_ref[].ccache

    level_to_flip_id = Dict()
    flip_probs = Dict{Any, Float64}()
    for (f_id, f) in flips
        flip_probs[f_id] = 0.5
        level_to_flip_id[level(ccache[f])] = f_id
    end

    logprobs = logprob([ccache[b] for b in qs], flip_probs)
    @assert exp(logprobs[ccache[qs[1]]]) ≈ 0.5
    @assert exp(logprobs[ccache[qs[2]]]) ≈ 0.25
    @assert exp(logprobs[ccache[qs[3]]]) ≈ 0.125

    for _ in 1:iters
        grad_sum = Dict(f_id => 0.0 for f_id in keys(flips))
        logprobs = logprob([ccache[b] for b in qs], flip_probs)
        for query in queries
            root = ccache[query.bits[1]]
            is_constant(root) && continue

            # println("rev fwd")
            grad_rev = grad_logprob(root, flip_probs, logprobs)
            grad_fwd = grad_logprob_fwd(root, flip_probs, logprobs)
            @assert grad_fwd ≈ grad_rev
            grad_sum += grad_rev

            for f_id in keys(flips)
                grad_sum[f_id] += grad_rev[flip_id]
            end
        end
        for f_id in keys(flips)
            flip_probs[f_id] -= grad_sum[f_id] * 0.1 / length(dataset)
            flip_probs[f_id] = clamp(flip_probs[f_id], 0.001, 0.999)
        end
    end
    println(flip_probs)
end

main()
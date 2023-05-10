unif_simulated(lo, hi) = Int(floor(rand()*(hi - lo + 1)) + lo)
flip_for_simulated(group) = rand() < get_group_prob(group)

function gen_bst_simulated(size, lo, hi)
    size == 0 && return DistLeaf()

    # Try changing the parameter to flip_for to a constant, which would force
    # all sizes to use the same probability.
    if flip_for_simulated(size)
        DistLeaf()
    else
        # The flips used in the uniform aren't tracked via flip_for, so we
        # don't learn their probabilities (this is on purpose - we could).
        x = DistUInt32(unif_simulated(unwrap_deterministic(lo), unwrap_deterministic(hi)))
        l = gen_bst_simulated(size-1, lo, x)
        r = gen_bst_simulated(size-1, x, hi)
        DistBranch(x, l, r)
    end
end

function unwrap_deterministic(x)
    d = pr(x)
    @assert length(d) == 1
    first(keys(d))
end

depth_sampled_dist = Dict(depth => 0. for depth in 0:INIT_SIZE)
ITERS = 2000
for _ in 1:ITERS
    d = depth(gen_bst_simulated(
        INIT_SIZE,
        DistUInt32(1),
        DistUInt32(2 * INIT_SIZE),
    ))
    depth_sampled_dist[unwrap_deterministic(d)] += 1
    # print_tree(unwrap_deterministic(d))
end
print_dict(Dict(k => v/ITERS for (k, v) in depth_sampled_dist))

nothing
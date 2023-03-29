# Cudd wrappers that encapsulate complementation - pretend complement arcs don't
# exist!
#
# Avoid using "Cudd_" functions outside of this file.

using CUDD

CuddNode = CUDD.DdNodePtr

is_constant(x::CuddNode) = isone(Cudd_IsConstant(x))

not(x::CuddNode) = Cudd_Not(x)

function high(x::CuddNode)
    @assert !is_constant(x)
    if Cudd_IsComplement(x)
        not(Cudd_T(x))
    else
        Cudd_T(x)
    end
end

function low(x::CuddNode)
    @assert !is_constant(x)
    if Cudd_IsComplement(x)
        not(Cudd_E(x))
    else
        Cudd_E(x)
    end
end

level(x::CuddNode) = Cudd_NodeReadIndex(x)

# Get a node's manager's one terminal without the manager
function get_one(x::CuddNode)
    while !is_constant(x)
        x = low(x)
    end
    Cudd_Regular(x)
end

function level_traversal(f, root::CuddNode)
    level_to_nodes = []
    function see(x)
        is_constant(x) && return
        i = level(x)
        while length(level_to_nodes) < i
            push!(level_to_nodes, Set())
        end
        push!(level_to_nodes[i], x)
    end

    see(root)
    cur_level = 1
    while cur_level <= length(level_to_nodes)
        for node in level_to_nodes[cur_level]
            f(node)
            see(low(node))
            see(high(node))
        end
        cur_level += 1
    end
end

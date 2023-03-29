using Dice

function genList(size)
    if size == 0
        return DistVector{DistUInt32}()
    end

    return ifelse(
        flip(0.5),
        prob_extend(
            genList(size-1),
            DistVector{DistUInt32}([DistUInt32(5)])
        ),
        DistVector{DistUInt32}()
    )
end


println("started")
l8 = genList(8)
dataset = [DistUInt32(5)] #[DistUInt32(x) for x in 0:8]
for x in dataset
    debug_info_ref = Ref{CuddDebugInfo}()
    d = pr(prob_equals(l8, x), algo=Cudd(debug_info_ref=debug_info_ref))
    println(debug_info_ref[])
    
    mgr, evidence, queries = debug_info_ref.mgr, debug_info_ref.evidence, debug_info_ref.queries
end

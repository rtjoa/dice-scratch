using Dice 
using Dice: Flip, ifelse, num_ir_nodes
using BenchmarkTools
localARGS = ARGS
# @show localARGS


function main()
    v = Vector()
    for i in 1:5
        time1 = @elapsed begin
                code = @dice begin   
                a = uniform(DistUInt{i+1}, i) + DistUInt{i+1}(1)
                b = uniform(DistUInt{i+1}, i) + DistUInt{i+1}(1)
                for _ = 1 : 1 + (i+1) ÷ log2(MathConstants.golden)
                    t = b
                    converged = prob_equals(b, DistUInt{i+1}(0))
                    amb = (a % b)
                    b = ifelse(converged, b, amb)
                    a = ifelse(converged, a, t)
                end
                gcd=a
                # prob_equals(g, DistUInt{i+1}(1))
                gcd
            end
        end
        time2 = @elapsed pr(code, ignore_errors=true)
        nodes = [num_ir_nodes(b) for b in code.returnvalue.bits]
        push!(v, (time1, time2, nodes))
    end
    v
end

main()


# 5-element Vector{Any}:
#  (0.004282084, 0.003823125, [239, 240])
#  (0.018343959, 0.032924125, [2646, 2646, 2646])
#  (0.035023417, 0.114200792, [10461, 10461, 10461, 10461])
#  (0.104550875, 0.523100541, [40622, 40622, 40622, 40622, 40622])
#  (0.263233458, 1.896923334, [119062, 119062, 119062, 119062, 119062, 119062])
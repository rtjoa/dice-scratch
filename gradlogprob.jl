
function gradlogprobability_cache(mgr, params)
    cache = Dict{Tuple{Ptr{Nothing},Bool},Any}()
    t = constant(mgr, true)
    cache[(t,false)] = [zero(Float64) for _ in params]
    cache[(t,true)] = [zero(Float64) for _ in params]
    cache
end

function gradlogprobability(mgr, x::Ptr{Nothing}, params, lpcache)
    cache = gradlogprobability_cache(mgr, params)
    grad = gradlogprobability(mgr, x, params, lpcache, cache)
    grad
end

function gradlogprobability(mgr, x::Ptr{Nothing}, params, lpcache, cache)
    rec(y, c) = 
        if Cudd_IsComplement(y)
            rec(Cudd_Regular(y), !c)   
        else get!(cache, (y,c)) do 
                v = decisionvar(mgr,y)
                grad = [
                    begin
                        fhi = lpcache[(Cudd_T(y), c)]
                        flo = lpcache[(Cudd_E(y), c)]
                        denom = param * exp(fhi) + (1 - param) * exp(flo)
                        if i == v + 1
                            (exp(fhi) - exp(flo))/denom
                        else
                            (param * exp(fhi) * rec(Cudd_T(y), c)[i] + (1 - param) * exp(flo) * rec(Cudd_E(y), c)[i])/denom
                        end
                    end
                    for (i, param) in enumerate(params) 
                ]
                grad
            end
        end
    
    rec(x, false)
end

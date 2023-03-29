prob(N, params) = begin
    if N == "one"
        return 1
    elseif N == "zero"
        return 1
    end
	i = Cudd_Var(N)
	params[i] * prob(CuddT(N), params) + (1 - params[i]) * prob(CuddF(N), params) 
end

prob_grad(N, params) = begin
    if N == "constant"
        return [0, 0]
    end
	i = Cudd_Var(N)
    res = (
        params[i] * prob_grad(CuddT(N), params)
        + (1-params[i]) * prob_grad(CuddF(N), params)
    )
    res[i] = prob(CuddT(N), params) - prob(CuddF(N), params)
    res
end


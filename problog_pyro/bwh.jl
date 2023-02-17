using Dice

localARGS = ARGS
num_bits = parse(Int64, localARGS[1])
nbpow = 2^num_bits

a = discrete([1/nbpow for _ in 1:nbpow])
b = discrete([1/nbpow for _ in 1:nbpow])

#~begin less
pr(a < b)
#~end

#~begin equals
pr(prob_equals(a, b))
#~end

#~begin sum
expectation(a + b)
#~end
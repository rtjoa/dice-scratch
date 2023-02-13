import torch
import pyro
import pyro.distributions as dist

import math

num_bits = 5

num_bits_pow_2 = 2 ** num_bits

@pyro.infer.config_enumerate
def model():
    a = pyro.sample('a', pyro.distributions.Categorical(torch.ones(num_bits_pow_2)))
    b = pyro.sample('b', pyro.distributions.Categorical(torch.ones(num_bits_pow_2)))
    
    # equals
    res = dist.Bernoulli((~(a < b) & ~(b < a)) * 1.0)

    # less than
    # res = dist.Bernoulli((a < b) * 1.0)

    # or we can do boolean circuits...    
    # x1 = pyro.sample('x1', dist.Bernoulli(0.01))
    # x2 = pyro.sample('x2', dist.Bernoulli(0.01))
    # res = dist.Bernoulli((x1.bool() & x2.bool()) * 1.0)

    pyro.sample(None, res, obs=torch.tensor(1.))


def guide(**kwargs):
    pass

elbo = pyro.infer.TraceEnum_ELBO(max_plate_nesting=0)
p_z = pyro.do(model, data={})
pr = math.exp(-elbo.loss(p_z, guide))
print(pr)

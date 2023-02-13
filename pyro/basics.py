import os
from datetime import datetime
import torch
import pyro
import pyro.distributions as dist

import math
from time import perf_counter



def guide(**kwargs):
    pass


@pyro.infer.config_enumerate
def less_than_model(num_bits):
    a = pyro.sample('a', dist.Categorical(torch.ones(2 ** num_bits)))
    b = pyro.sample('b', dist.Categorical(torch.ones(2 ** num_bits)))
    res = dist.Bernoulli((a < b) * 1.0)
    pyro.sample(None, res, obs=torch.tensor(1.))


@pyro.infer.config_enumerate
def equals_model(num_bits):
    a = pyro.sample('a', dist.Categorical(torch.ones(2 ** num_bits)))
    b = pyro.sample('b', dist.Categorical(torch.ones(2 ** num_bits)))
    res = dist.Bernoulli((a == b) * 1.0)
    pyro.sample(None, res, obs=torch.tensor(1.))


@pyro.infer.config_enumerate
def sum_model(num_bits, bit_of_interest):
    a = pyro.sample('a', dist.Categorical(torch.ones(2 ** num_bits)))
    b = pyro.sample('b', dist.Categorical(torch.ones(2 ** num_bits)))
    res = dist.Bernoulli((((a + b) >> bit_of_interest) & 1) * 1.0)
    pyro.sample(None, res, obs=torch.tensor(1.))


def run_sum(num_bits):
    prs = []
    for bit_of_interest in range(num_bits + 1):
        elbo = pyro.infer.TraceEnum_ELBO(max_plate_nesting=0)
        p_z = pyro.do(sum_model, data={})
        pr = math.exp(-elbo.loss(p_z, guide, num_bits=num_bits,
                      bit_of_interest=bit_of_interest))
        prs.append(pr)
    return prs


def run_less_than(num_bits):
    elbo = pyro.infer.TraceEnum_ELBO(max_plate_nesting=0)
    p_z = pyro.do(less_than_model, data={})
    pr = math.exp(-elbo.loss(p_z, guide, num_bits=num_bits))
    return pr


def run_equals(num_bits):
    elbo = pyro.infer.TraceEnum_ELBO(max_plate_nesting=0)
    p_z = pyro.do(equals_model, data={})
    pr = math.exp(-elbo.loss(p_z, guide, num_bits=num_bits))
    return pr


NS = list(range(5, 7))
OUTPUT_DIR = "output"
TESTS = [
    (run_less_than, "less_than"),
    (run_equals, "equals"),
    (run_sum, "sum"),
]

timestamp = datetime.now().strftime("%Y-%m-%d_%Hh%Mm%Ss")


if not os.path.isdir(OUTPUT_DIR):
    os.mkdir(OUTPUT_DIR)

for runner, name in [
    (run_less_than, "less_than"),
    (run_equals, "equals"),
    (run_sum, "sum"),
]:
    for num_bits in NS:
        tic = perf_counter()
        res = runner(num_bits)
        toc = perf_counter()

        print(name, num_bits, toc - tic, res)

        output_path = os.path.join(OUTPUT_DIR, f"{name}_{timestamp}.csv")
        with open(output_path, "a") as output_file:
            output_file.write(
                '\t'.join([name, str(num_bits), str(toc - tic)]) + "\n")
            if toc - tic > 120:
                continue

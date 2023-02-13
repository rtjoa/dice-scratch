n = 10


def prin(s):
  print(s, end='')


def print_rule(head, atoms):
  print(head + " :- " + ", ".join(atoms) + ".")


def uniform(name, num_bits):
  for i in range(num_bits):
    print(f"0.5::{name}{i}(0); 0.5::{name}{i}({2**i}).")
  print_rule(f"{name}(X)", [f"{name}{i}(X{i})" for i in range(num_bits)] +
             ["X is " + " + ".join(f"X{i}" for i in range(num_bits))])


def uniform_sample(name, num_bits):
  print(f"""
{name}_domain(0).
{name}_domain(N) :- {name}_domain(Nm1), N is Nm1 + 1, N < {2 ** num_bits}.

P::{name}_sample_now(X) :- {name}_domain(X), P is 1/(X + 1).
{name}_sample(X, X) :- {name}_sample_now(X).
{name}_sample(M, X) :- {name}_domain(M), \+ {name}_sample_now(M), Mm1 is M - 1, {name}_sample(Mm1,X).

{name}(X) :- {name}_sample({2 ** num_bits - 1}, X).
""")


# uniform("a", 10)
# uniform("b", 10)

uniform_sample("a", 5)
uniform_sample("b", 5)
print("""
% https://stackoverflow.com/questions/22450582/program-for-finding-gcd-in-prolog
gcd(X,Y,G) :- X=Y, G=X.
gcd(X,Y,G) :- X<Y, Y1 is Y-X, gcd(X,Y1,G).
gcd(X,Y,G) :- X>Y ,gcd(Y,X,G).

isone :- a(A), b(B), Ap1 is A + 1, Bp1 is B + 1, gcd(Ap1, Bp1, 1).
query(isone).

""")

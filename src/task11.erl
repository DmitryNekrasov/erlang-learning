-module(task11).
-author("nekrasov").

-export([main/0]).

gcd(A, 0) -> A;
gcd(A, B) -> gcd(B, A rem B).

gcdList(X, []) -> X;
gcdList(_, [H|T]) -> gcd(H, gcdList(H, T)).

gcdList([]) -> 1;
gcdList([H|T]) -> gcdList(H, [H|T]).

main() ->
  Gcd = gcdList([150, 45, 90, 105, 24]),
  erlang:display(Gcd).

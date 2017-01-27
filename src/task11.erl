-module(task11).
-author("nekrasov").

-export([main/0]).

gcd(A, 0) -> A;
gcd(A, B) -> gcd(B, A rem B).

gcd([H]) -> H;
gcd([H|T]) -> gcd(H, gcd(T)).

main() ->
  Gcd = gcd([150, 45, 90, 105, 24]),
  erlang:display(Gcd).

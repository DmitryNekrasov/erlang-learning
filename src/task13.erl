-module(task13).
-author("nekrasov").

-export([main/0]).

binPow(_, 0) -> 1;
binPow(A, N) when N rem 2 == 0 ->
  B = binPow(A, N div 2),
  B * B;
binPow(A, N) -> A * binPow(A, N - 1).

binPowList([], []) -> [];
binPowList([H1|T1], [H2|T2]) -> [binPow(H1, H2) | binPowList(T1, T2)].

main() ->
  A = [2, 3, 7, 15, 1],
  B = [3, 4, 8, 5, 100000000000000000000],
  R = binPowList(A, B),
  erlang:display(R).
-module(task06).
-author("nekrasov").

-export([main/0]).

calc([mul, L, R]) -> calc(L) * calc(R);
calc([di, L, R]) -> calc(L) / calc(R);
calc([plus, L, R]) -> calc(L) + calc(R);
calc([minus, L, R]) -> calc(L) - calc(R);
calc(V) -> V.

main() ->
  Tree = [di, [plus, [plus, [plus, [mul, [plus, 3, 5], 4], [di, [mul, 8, 20], 10]], [mul, [minus, 4, 3], 8]], [di, 8, [mul, 9, 4]]], 10],
  R = calc(Tree),
  erlang:display(R).
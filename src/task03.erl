-module(task03).
-author("nekrasov").

-export([main/0]).

bubbleSwap([]) -> [];
bubbleSwap([H1, H2 | T]) when H1 > H2 -> [H2 | bubbleSwap([H1|T])];
bubbleSwap([H|T]) -> [H | bubbleSwap(T)].

bubbleSort(L, 0) -> L;
bubbleSort(L, N) -> bubbleSort(bubbleSwap(L), N - 1).

bubbleSort(L) -> bubbleSort(L, lists:flatlength(L)).

main() ->
  L = bubbleSort([7, 6, 5, 50, 3, 2, 1]),
  erlang:display(L).
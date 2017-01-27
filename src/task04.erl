-module(task04).
-author("nekrasov").

-export([main/0]).

merge(L, []) -> L;
merge([], L) -> L;
merge([H1 | T1], [H2 | T2]) when H1 < H2 -> [H1 | merge(T1, [H2 | T2])];
merge([H1 | T1], [H2 | T2]) -> [H2 | merge([H1 | T1], T2)].

mergeSort([]) -> [];
mergeSort([H]) -> [H];
mergeSort(L) ->
  Half = lists:flatlength(L) div 2,
  S1 = lists:sublist(L, 1, Half),
  S2 = lists:sublist(L, Half + 1, Half + 1),
  merge(mergeSort(S1), mergeSort(S2)).

main() ->
  R = mergeSort([5, 2, 8, 7, 25, 3, 47, 15, 12, 10, 18, 5, 105, 88]),
  erlang:display(R).
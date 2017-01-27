-module(task01).
-author("nekrasov").

-export([main/0]).

makeList(0) -> [];
makeList(N) -> makeList(N div 10) ++ [N rem 10].

main() ->
  L = makeList(1234567890),
  erlang:display(L).

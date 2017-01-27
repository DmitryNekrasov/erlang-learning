-module(task02).
-author("nekrasov").

-export([main/0]).

getNumber(0) -> [];
getNumber(N) -> [N | getNumber(N - 1)].

getDividerList(N) -> [X || X <- getNumber(N - 1), N rem X == 0].

getPerfectNumber(N) -> [X || X <- lists:reverse(getNumber(N)), X == lists:sum(getDividerList(X))].

main() ->
  P = getPerfectNumber(10000),
  erlang:display(P).
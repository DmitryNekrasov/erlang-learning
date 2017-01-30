-module(ping_pong).
-author("nekrasov").

-export([main/0]).

ping(PidPong) ->
  io:format("I'm ping, pids are : ~w ~w ~n", [PidPong, self()]),
  PidPong ! {ping, self()},
  io:format("waiting for pong...~n"),
  receive
    pong -> io:format("PONG received~n")
  end.

pong() ->
  io:format("I'm pong, my pid is : ~w ~n", [self()]),
  receive
    {ping, PidPing} ->
      io:format("PING received, sending pong~n"),
      PidPing ! pong
  end.

main() ->
  spawn(fun() -> ping(spawn(fun() -> pong() end)) end).

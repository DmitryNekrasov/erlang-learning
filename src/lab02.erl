-module(lab02).
-author("nekrasov").

-export([main/0]).

teamAction() ->
  Rand = rand:uniform(2),
  if
    Rand == 1 -> send_task;
    true -> get_monitor
  end.

team(PidClientApp) ->
  TeamAction = teamAction(),
  if
    TeamAction == send_task ->
      ProblemId = rand:uniform(100),
      io:format("Team submit Problem ~w~n", [ProblemId]),
      PidClientApp ! {team, self(), ProblemId};
    true ->
      io:format("Team check monitor~n"),
      PidClientApp ! {team, self()}
  end,
  receive
    client_app -> io:format("Team get monitor~n")
  end.

utility(PidMonitor, PidTeam) ->
  io:format("Client App requested monitor~n"),
  PidMonitor ! {client_app, self()},
  receive
    monitor ->
      io:format("Client App get monitor~n"),
      io:format("Client App send monitor to team~n"),
      PidTeam ! client_app
  end.

clientApp(PidMonitor, PidController) ->
  receive
    {team, PidTeam} ->
      utility(PidMonitor, PidTeam);
    {team, PidTeam, ProblemId} ->
      io:format("Client App send problem ~w~n", [ProblemId]),
      PidController ! {client_app, PidMonitor, ProblemId},
      utility(PidMonitor, PidTeam)
  end.

monitor() ->
  receive
    {client_app, ClientAppPid} ->
      io:format("Monitor returned to client app~n"),
      ClientAppPid ! monitor;
    {controller, ProblemId, Verdict} ->
      io:format("Monitor get ~s (Problem ~w)~n", [Verdict, ProblemId])
  end.

verdict() ->
  Rand = rand:uniform(5),
  if
    Rand == 1 -> "AC";
    Rand == 2 -> "WA";
    Rand == 3 -> "TL";
    Rand == 4 -> "ML";
    true -> "RE"
  end.

controller() ->
  receive
    {client_app, PidMonitor, ProblemId} ->
      io:format("Controller get Problem ~w~n", [ProblemId]),
      io:format("Controller update monitor~n"),
      PidMonitor ! {controller, ProblemId, verdict()}
  end.

for(Callback, 1) -> Callback();
for(Callback, N) ->
  Callback(),
  for(Callback, N - 1).

main() ->
  N = 4,
  PidMonitor = spawn(fun() -> for(fun() -> monitor() end, N) end),
  PidController = spawn(fun() -> for(fun() -> controller() end, N) end),
  PidClientApp = spawn(fun() -> for(fun() -> clientApp(PidMonitor, PidController) end, N) end),
  spawn(fun() -> for(fun() -> team(PidClientApp) end, N) end).
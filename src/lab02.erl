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
  PidClientApp ! {team, self(), TeamAction},
  receive
    client_app -> io:format("(Team) Client App received~n")
  end.

utility(PidMonitor, PidTeam) ->
  PidMonitor ! {client_app, self()},
  receive
    monitor ->
      io:format("(ClientApp) Monitor received~n"),
      PidTeam ! client_app
  end.

clientApp(PidMonitor, PidController) ->
  receive
    {team, PidTeam, get_monitor} ->
      utility(PidMonitor, PidTeam);
    {team, PidTeam, send_task} ->
      PidController ! {client_app, PidMonitor},
      utility(PidMonitor, PidTeam)
  end.

monitor() ->
  receive
    {client_app, ClientAppPid} ->
      io:format("(Monitor) Client App received~n"),
      ClientAppPid ! monitor;
    controller ->
      io:format("(Monitor) Controller received~n")
  end.

controller() ->
  receive
    {client_app, PidMonitor} ->
      io:format("(Controller) Client App received~n"),
      PidMonitor ! controller
  end.

for(Callback, 1) -> Callback();
for(Callback, N) ->
  Callback(),
  for(Callback, N - 1).

main() ->
  N = 2,
  PidMonitor = spawn(fun() -> for(fun() -> monitor() end, N) end),
  PidController = spawn(fun() -> for(fun() -> controller() end, N) end),
  PidClientApp = spawn(fun() -> for(fun() -> clientApp(PidMonitor, PidController) end, N) end),
  spawn(fun() -> for(fun() -> team(PidClientApp) end, N) end).
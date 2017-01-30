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
  io:format("I'm Team, my pid is : ~w ~n", [self()]),
  PidClientApp ! {team, self(), teamAction()},
  receive
    client_app -> io:format("(Team) Client App received~n")
  end.

clientApp(PidMonitor, PidController) ->
  io:format("I'm Client App, my pid is : ~w ~n", [self()]),
  receive
    {team, PidTeam, get_monitor} ->
      PidMonitor ! {client_app, self()},
      receive
        monitor ->
          io:format("(ClientApp) Monitor received~n"),
          PidTeam ! client_app
      end;
    {team, _, send_task} ->
      PidController ! {client_app, PidMonitor}
  end.

monitor() ->
  io:format("I'm Monitor, my pid is : ~w ~n", [self()]),
  receive
    {client_app, ClientAppPid} ->
      io:format("(Monitor) Client App received~n"),
      ClientAppPid ! monitor;
    controller ->
      io:format("(Monitor) Controller received~n")
  end.

controller() ->
  io:format("I'm Controller, my pid is : ~w ~n", [self()]),
  receive
    {client_app, PidMonitor} ->
      io:format("(Controller) Client App received~n"),
      PidMonitor ! controller
  end.

main() ->
  PidMonitor = spawn(fun() -> monitor() end),
  PidController = spawn(fun() -> controller() end),
  PidClientApp = spawn(fun() -> clientApp(PidMonitor, PidController) end),
  spawn(fun() -> team(PidClientApp) end),
  erlang:display(hello).
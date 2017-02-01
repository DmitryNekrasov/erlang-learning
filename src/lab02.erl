-module(lab02).
-author("nekrasov").

-export([main/0, startMonitor/0, startTestingSystem/0, startController/1, startClientApp/2, startTeam/1]).

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
      timer:sleep(random:uniform(1000)),
      io:format("Team submit Problem ~w~n", [ProblemId]),
      PidClientApp ! {team, self(), ProblemId};
    true ->
      timer:sleep(random:uniform(1000)),
      io:format("Team check monitor~n"),
      PidClientApp ! {team, self()}
  end,
  receive
    client_app ->
      io:format("Team get monitor~n"),
      team(PidClientApp)
  end.

utility(PidMonitor, PidTeam) ->
  timer:sleep(random:uniform(100)),
  io:format("Client App requested monitor~n"),
  PidMonitor ! {client_app, self()},
  receive
    monitor ->
      io:format("Client App get monitor~n"),
      timer:sleep(random:uniform(1000)),
      io:format("Client App send monitor to team~n"),
      PidTeam ! client_app
  end.

clientApp(PidMonitor, PidController) ->
  receive
    {team, PidTeam} ->
      utility(PidMonitor, PidTeam),
      clientApp(PidMonitor, PidController);
    {team, PidTeam, ProblemId} ->
      timer:sleep(random:uniform(1000)),
      io:format("Client App send problem ~w~n", [ProblemId]),
      PidController ! {client_app, PidMonitor, ProblemId},
      utility(PidMonitor, PidTeam),
      clientApp(PidMonitor, PidController)
  end.

monitor() ->
  receive
    {client_app, ClientAppPid} ->
      timer:sleep(random:uniform(1000)),
      io:format("Monitor returned to client app~n"),
      ClientAppPid ! monitor,
      monitor();
    {controller, ProblemId, Verdict} ->
      io:format("Monitor get ~s (Problem ~w)~n", [Verdict, ProblemId]),
      monitor()
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

controller(PidTestingSystem) ->
  receive
    {client_app, PidMonitor, ProblemId} ->
      io:format("Controller get Problem ~w~n", [ProblemId]),
      timer:sleep(random:uniform(1000)),
      io:format("Controller send Problem ~w to Testing System~n", [ProblemId]),
      PidTestingSystem ! {controller, self(), ProblemId},
      receive
        {testing_system, ProblemId, Verdict} ->
          io:format("Controller get verdict - ~s (Problem ~w)~n", [Verdict, ProblemId]),
          timer:sleep(random:uniform(1000)),
          io:format("Controller update monitor~n"),
          PidMonitor ! {controller, ProblemId, Verdict},
          controller(PidTestingSystem)
      end
  end.

testingSystem() ->
  receive
    {controller, PidController, ProblemId} ->
      io:format("Testing System get Problem ~w~n", [ProblemId]),
      Verdict = verdict(),
      io:format("Testing System get verdict - ~s (Problem ~w)~n", [Verdict, ProblemId]),
      timer:sleep(random:uniform(1000)),
      io:format("Testing System send verdict to controller~n"),
      PidController ! {testing_system, ProblemId, Verdict},
      testingSystem()
  end.

main() ->
  PidMonitor = spawn(fun() -> monitor() end),
  PidTestingSystem = spawn(fun() ->  testingSystem() end),
  PidController = spawn(fun() -> controller(PidTestingSystem) end),
  PidClientApp = spawn(fun() -> clientApp(PidMonitor, PidController) end),
  spawn(fun() -> team(PidClientApp) end),
  timer:sleep(300000).

startMonitor() ->
  PidMonitor = spawn(fun() -> monitor() end),
  global:register_name(monitor, PidMonitor),
  timer:sleep(300000).

startTestingSystem() ->
  PidTestingSystem = spawn(fun() ->  testingSystem() end),
  global:register_name(testing_system, PidTestingSystem),
  timer:sleep(300000).

startController(pong) ->
  PidTestingSystem = global:whereis_name(testing_system),
  PidController = spawn(fun() -> controller(PidTestingSystem) end),
  global:register_name(controller, PidController),
  timer:sleep(300000);
startController(_) ->
  erlang:display(wait),
  timer:sleep(1000),
  startController(net_adm:ping('testing_system@name.local')).

startClientApp(pong, pong) ->
  PidMonitor = global:whereis_name(monitor),
  PidController = global:whereis_name(controller),
  PidClientApp = spawn(fun() -> clientApp(PidMonitor, PidController) end),
  global:register_name(client_app, PidClientApp),
  timer:sleep(300000);
startClientApp(_, _) ->
  erlang:display(wait),
  timer:sleep(1000),
  startClientApp(net_adm:ping('monitor@name.local'), net_adm:ping('controller@name.local')).

startTeam(pong) ->
  PidClientApp = global:whereis_name(client_app),
  PidTeam = spawn(fun() -> team(PidClientApp) end),
  global:register_name(team, PidTeam),
  timer:sleep(300000);
startTeam(_) ->
  erlang:display(wait),
  timer:sleep(1000),
  startTeam(net_adm:ping('client_app@name.local')).
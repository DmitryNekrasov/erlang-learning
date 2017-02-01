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
  timer:sleep(20000).
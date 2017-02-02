-module(lab02).
-author("nekrasov").

-export([main/0, startMonitor/1, startTestingSystem/1, startController/2, startClientApp/3, startTeam/1]).

formatMap(Map) -> formatList(maps:to_list(Map)).

formatList(List) ->
  io:format("["),
  formatListU(List),
  io:format("]~n").

formatListU([]) -> ok;
formatListU([H]) -> io:format("~p", [H]);
formatListU([H | T]) ->
  io:format("~p, ", [H]),
  formatListU(T).

teamAction() ->
  Rand = rand:uniform(2),
  if
    Rand == 1 -> send_task;
    true -> get_monitor
  end.

generateProblemId(Monitor) -> generateProblemId(Monitor, 0, "AC").

generateProblemId(Monitor, _, "AC") ->
  CandidateProblemId = rand:uniform(maps:size(Monitor)),
  CandidateVerdict = maps:get(CandidateProblemId, Monitor),
  generateProblemId(Monitor, CandidateProblemId, CandidateVerdict);
generateProblemId(_, ProblemId, _) -> ProblemId.

team(PidClientApp, ProblemId) ->
  TeamAction = teamAction(),
  if
    TeamAction == send_task ->
      timer:sleep(random:uniform(1000)),
      io:format("Team submit Problem ~w~n", [ProblemId]),
      PidClientApp ! {team, self(), ProblemId};
    true ->
      timer:sleep(random:uniform(1000)),
      io:format("Team check monitor~n"),
      PidClientApp ! {team, self()}
  end,
  receive
    {client_app, Monitor} ->
      io:format("Team get monitor: "),
      formatMap(Monitor),
      NewProblemId = generateProblemId(Monitor),
      team(PidClientApp, NewProblemId)
  end.

utility(PidMonitor, PidTeam) ->
  timer:sleep(random:uniform(100)),
  io:format("Client App requested monitor~n"),
  PidMonitor ! {client_app, self()},
  receive
    {monitor, Monitor} ->
      io:format("Client App get monitor: "),
      formatMap(Monitor),
      timer:sleep(random:uniform(1000)),
      io:format("Client App send monitor to team~n"),
      PidTeam ! {client_app, Monitor}
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

monitor(Monitor) ->
  receive
    {client_app, ClientAppPid} ->
      timer:sleep(random:uniform(1000)),
      io:format("Monitor returned to client app~n"),
      ClientAppPid ! {monitor, Monitor},
      monitor(Monitor);
    {controller, ProblemId, Verdict} ->
      io:format("Monitor get ~s (Problem ~w)~n", [Verdict, ProblemId]),
      monitor(maps:put(ProblemId, Verdict, Monitor))
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

initMonitor(Map, 0) -> Map;
initMonitor(Map, N) ->
  initMonitor(maps:put(N, "--", Map), N - 1).

main() ->
  ProblemCount = 5,
  PidMonitor = spawn(fun() -> monitor(initMonitor(maps:new(), ProblemCount)) end),
  PidTestingSystem = spawn(fun() ->  testingSystem() end),
  PidController = spawn(fun() -> controller(PidTestingSystem) end),
  PidClientApp = spawn(fun() -> clientApp(PidMonitor, PidController) end),
  spawn(fun() -> team(PidClientApp, rand:uniform(ProblemCount)) end),
  timer:sleep(300000).

wait() ->
  erlang:display(wait),
  timer:sleep(1000).

pingMonitor(_, pong) -> ok;
pingMonitor(Name, _) ->
  wait(),
  pingMonitor(Name, net_adm:ping(Name)).

pingTestingSystem(_, pong) -> ok;
pingTestingSystem(Name, _) ->
  wait(),
  pingTestingSystem(Name, net_adm:ping(Name)).

pingController(_, pong) -> ok;
pingController(Name, _) ->
  wait(),
  pingController(Name, net_adm:ping(Name)).

pingClientApp(_, pong) -> ok;
pingClientApp(Name, _) ->
  wait(),
  pingClientApp(Name, net_adm:ping(Name)).

pingTeam(_, pong) -> ok;
pingTeam(Name, _) ->
  wait(),
  pingTeam(Name, net_adm:ping(Name)).

startMonitor(ClientAppNodeName) ->
  global:register_name(monitor, self()),
  pingClientApp(ClientAppNodeName, pang),
  monitor(initMonitor(maps:new(), 5)).

startTestingSystem(ControllerNodeName) ->
  global:register_name(testing_system, self()),
  pingController(ControllerNodeName, pang),
  testingSystem().

startController(TestingSystemNodeName, MonitorNodeName) ->
  global:register_name(controller, self()),
  pingTestingSystem(TestingSystemNodeName, pang),
  pingMonitor(MonitorNodeName, pang),
  PidTestingSystem = global:whereis_name(testing_system),
  controller(PidTestingSystem).

startClientApp(ControllerNodeName, TeamNodeName, MonitorNodeName) ->
  global:register_name(client_app, self()),
  pingController(ControllerNodeName, pang),
  pingTeam(TeamNodeName, pang),
  pingMonitor(MonitorNodeName, pang),
  PidMonitor = global:whereis_name(monitor),
  PidController = global:whereis_name(controller),
  clientApp(PidMonitor, PidController).

startTeam(ClientAppNodeName) ->
  global:register_name(team, self()),
  pingClientApp(ClientAppNodeName, pang),
  PidClientApp = global:whereis_name(client_app),
  ProblemCount = 5,
  team(PidClientApp, rand:uniform(ProblemCount)).
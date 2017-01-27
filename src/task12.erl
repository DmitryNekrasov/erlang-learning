-module(task12).
-author("nekrasov").

-export([main/0]).

height([]) -> 0;
height([{_, Height}, _, _]) -> Height.

balanceFactor([_, Left, Right]) -> height(Right) - height(Left).

fixHeight([{Key, _}, Left, Right]) ->
  [{Key, max(height(Left), height(Right)) + 1}, Left, Right].

rotateRight([P, [Q, QLeft, QRight], PRight]) ->
  NewQRight = fixHeight([P, QRight, PRight]),
  fixHeight([Q, QLeft, NewQRight]).

rotateLeft([Q, QLeft, [P, PLeft, PRight]]) ->
  NewPLeft = fixHeight([Q, QLeft, PLeft]),
  fixHeight([P, NewPLeft, PRight]).

utilityRight([P, Left, Right], RFactor) when RFactor < 0 ->
  [P, Left, rotateRight(Right)];
utilityRight(Node, _) -> Node.

utilityLeft([P, Left, Right], LFactor) when LFactor > 0 ->
  [P, rotateLeft(Left), Right];
utilityLeft(Node, _) -> Node.

balance([P, Left, Right], 2) ->
  rotateLeft(utilityRight([P, Left, Right], balanceFactor(Right)));
balance([P, Left, Right], -2) ->
  rotateRight(utilityLeft([P, Left, Right], balanceFactor(Left)));
balance(Node, _) -> Node.

balance(Node) ->
  balance(fixHeight(Node), balanceFactor(Node)).

insert([], Key) -> [{Key, 1}, [], []];
insert([{NodeKey, NodeHeight}, Left, Right], Key) when Key < NodeKey ->
  balance([{NodeKey, NodeHeight}, insert(Left, Key), Right]);
insert([{NodeKey, NodeHeight}, Left, Right], Key) ->
  balance([{NodeKey, NodeHeight}, Left, insert(Right, Key)]).

insertKeys(Node, []) -> Node;
insertKeys(Node, [H | T]) -> insertKeys(insert(Node, H), T).

makeTree(Keys) -> insertKeys([], Keys).

main() ->
  Tree = makeTree([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]),
  erlang:display(Tree).
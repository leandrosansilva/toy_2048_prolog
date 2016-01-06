% Vim, this is Prolog!

empty_field([H, W], field([], Empty)) :-
  succ(MaxX, W),
  succ(MaxY, H),
  findall(
    [X, Y], (
      between(0, MaxX, X), 
      between(0, MaxY, Y)),
    GenEmpty),
  list_to_ord_set(GenEmpty, Empty).

% it's private because in the real game
% only tile with value 2 or 4 can be added
add_tile_private(Field, Tile , NewField) :-
  add_tiles(Field, [Tile], NewField).

add_tile(Field, Tile, NewField) :- 
  tile(_, _, Value) = Tile,
  member(Value, [2, 4]), !,
  add_tile_private(Field, Tile, NewField).

add_tiles(field(Used, Empty), TilesRaw, field(NewUsed, NewEmpty)) :-
  list_to_ord_set(TilesRaw, Tiles),
  ord_union(Used, Tiles, NewUsed),
  findall([X, Y], member(tile(X, Y, _), TilesRaw), PositionsRaw),
  list_to_ord_set(PositionsRaw, Positions),
  ord_subtract(Empty, Positions, NewEmpty).
 
next_tile_value(Value, NextValue) :-
  NextValue is Value * 2.

merge_tiles(tile(X1, Y1, V), tile(X2, Y2, V), Dir, tile(X3, Y3, NewValue)) :-
  % FIXME: I still can refactor this code to remove copy-paste...
  next_tile_value(V, NewValue),
  (
    Dir = left,
    Y1 = Y2,
    max_list([X1, X2], X3);

    Dir = right,
    Y1 = Y2,
    min_list([X1, X2], X3);

    Dir = up,
    X1 = X2,
    min_list([Y1, Y2], Y3);

    Dir = down,
    X1 = X2,
    max_list([Y1, Y2], Y3)
  ), !.

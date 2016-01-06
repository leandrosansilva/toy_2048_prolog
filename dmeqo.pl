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

merge_tiles(Tile1, Tile2, Dir, Tile3) :-
  Tile1 = tile(X1, Y1, V),
  Tile2 = tile(X2, Y2, V),
  Tile3 = tile(X3, Y3, NewValue),
  Tile1 \= Tile2,
  next_tile_value(V, NewValue),

  % FIXME: I still can refactor this code to remove copy-paste...
  (
    Dir = left,
    Y1 = Y2,
    Y3 = Y1,
    max_list([X1, X2], X3), !;

    Dir = right,
    Y1 = Y2,
    Y3 = Y1,
    min_list([X1, X2], X3), !;

    Dir = up,
    X1 = X2,
    X3 = X1,
    min_list([Y1, Y2], Y3), !;

    Dir = down,
    X1 = X2,
    X3 = X1,
    max_list([Y1, Y2], Y3)
  ).
  % nl, write("Merge dir: "),
  % write(Dir), write(" "),
  % write(Tile1), write(" "),
  % write(Tile2), write(" to: "),
  % write(Tile3), nl.

find_mergeables(Field, Dir, Mergeables) :-
  up = Dir,
  findall(
    mergeable(Tile1, Tile2, Merged), 
    merge_tiles(Field, Tile1, Tile2, Merged, Dir), 
    Mergeables).

merge_tiles(field(Used, Empty), Tile1, Tile2, Merged, Dir) :-
  member(Tile1, Used),
  member(Tile2, Used),
  compare(<, Tile1, Tile2),
  merge_tiles(Tile1, Tile2, Dir, Merged),
  tiles_connect(Tile1, Tile2, Dir, Empty).

tiles_connect(tile(X, Y1, _), tile(X, Y2, _), up, Empty) :-
  msort([Y1, Y2], [PrevBegin, SuccEnd]),
  succ(PrevBegin, Begin),
  succ(End, SuccEnd),
  findall([X, Y], between(Begin, End, Y), BetweenRaw),
  list_to_ord_set(BetweenRaw, Between),
  ord_subset(Between, Empty).

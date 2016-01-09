% Vim, this is Prolog!

empty_field([H, W], field([], Empty)) :-
  succ(MaxX, W),
  succ(MaxY, H),
  findall(
    [X, Y], (
      between(0, MaxX, X),
      between(0, MaxY, Y)),
    GenEmpty),
  sort(GenEmpty, Empty).

% it's private because in the real game
% only tile with value 2 or 4 can be added
add_tile_private(Field, Tile , NewField) :-
  add_tiles(Field, [Tile], NewField).

add_tile(Field, Tile, NewField) :-
  tile(_, _, Value) = Tile,
  member(Value, [2, 4]), !,
  add_tile_private(Field, Tile, NewField).

add_tiles(field(Used, Empty), TilesRaw, field(NewUsed, NewEmpty)) :-
  sort(TilesRaw, Tiles),
  ord_union(Used, Tiles, NewUsed),
  findall([X, Y], member(tile(X, Y, _), TilesRaw), PositionsRaw),
  sort(PositionsRaw, Positions),
  ord_subtract(Empty, Positions, NewEmpty).

next_tile_value(Value, NextValue) :-
  NextValue is Value * 2.

merge_tiles(Tile1, Tile2, Dir, Tile3) :-
  Tile1 = tile(X1, Y1, V),
  Tile2 = tile(X2, Y2, V),
  Tile3 = tile(X3, Y3, NewValue),
  Tile1 \= Tile2,
  next_tile_value(V, NewValue),

  (member(Dir, [left, right]), Y1 = Y2, Y3 = Y1;
   member(Dir, [up, down]), X1 = X2, X3 = X1),

  % FIXME: I still can refactor this code to remove copy-paste...
  (Dir = left, min_list([X1, X2], X3), !;
   Dir = right, max_list([X1, X2], X3), !;
   Dir = up, min_list([Y1, Y2], Y3), !;
   Dir = down, max_list([Y1, Y2], Y3)).

find_mergeables(Field, Dir, Mergeables) :-
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

% Is possible to "trace a line" between two tiles?
tiles_connect(tile(X1, Y1, _), tile(X2, Y2, _), Dir, Empty) :-
  forall(between_tiles(Dir, [X1, Y1], [X2, Y2], [X, Y]),
         ord_memberchk([X, Y], Empty)).

% TODO: It's still possible to refactor between_tiles.
between_tiles(Dir, [X, Y1], [X, Y2], [X, Y]) :-
  member(Dir, [up, down]),
  msort([Y1, Y2], [PrevBegin, SuccEnd]),
  succ(PrevBegin, Begin),
  succ(End, SuccEnd),
  between(Begin, End, Y).

between_tiles(Dir, [X1, Y], [X2, Y], [X, Y]) :-
  member(Dir, [left, right]),
  msort([X1, X2], [PrevBegin, SuccEnd]),
  succ(PrevBegin, Begin),
  succ(End, SuccEnd),
  between(Begin, End, X).

% FIXME: this predicate is way too complex :-(
merge_tiles_on_field(Field, Dir, MergedField) :-
  field(Used, _) = Field,
  find_mergeables(Field, Dir, Mergeables),

  findall(Tile, (
    member(mergeable(Tile, _, _), Mergeables);
    member(mergeable(_, Tile, _), Mergeables);
    member(mergeable(_, _, Tile), Mergeables)
  ), AllNewTilesRaw),
  sort(AllNewTilesRaw, AllNewTiles),
  ord_symdiff(Used, AllNewTiles, MergedUsed),
  empty_field([4, 4], EmptyField),
  add_tiles(EmptyField, MergedUsed, MergedField).

tiles_moves(field(Used, Empty), Dir, Moves) :-
  findall(
    move(Source, Dest),(
      member(Source, Used),
      new_tile_position(Source, Dir, Empty, Dest),
      Source \= Dest),
    Moves).

% FIXME: 3 is the last column, and should come from the field
new_tile_position(tile(X1, Y, V), right, Empty, tile(X2, Y, V)) :-
  succ(X1, NextColumn),
  aggregate_all(count, (
    between(NextColumn, 3, Column),
    ord_memberchk([Column, Y], Empty)),
    NumberOfSpaces),
  X2 is X1 + NumberOfSpaces.

new_tile_position(tile(X1, Y, V), left, Empty, tile(X2, Y, V)) :-
  succ(PrevColumn, X1),
  aggregate_all(count, (
    between(0, PrevColumn, Column),
    ord_memberchk([Column, Y], Empty)),
    NumberOfSpaces),
  X2 is X1 - NumberOfSpaces.

new_tile_position(tile(X, Y1, V), up, Empty, tile(X, Y2, V)) :-
  succ(PrevRow, Y1),
  aggregate_all(count, (
    between(0, PrevRow, Row),
    ord_memberchk([X, Row], Empty)),
    NumberOfSpaces),
  Y2 is Y1 - NumberOfSpaces.

new_tile_position(tile(X, Y1, V), down, Empty, tile(X, Y2, V)) :-
  succ(Y1, NextRow),
  aggregate_all(count, (
    between(NextRow, 3, Row),
    ord_memberchk([X, Row], Empty)),
    NumberOfSpaces),
  Y2 is Y1 + NumberOfSpaces.

move_tiles(Field, Dir, MovedField) :-
  merge_tiles_on_field(Field, Dir, MergedField),
  move_tiles_on_field(MergedField, Dir, MovedField).

% FIXME: I know, it's copy-paste. I'll refactor it later...
move_tiles_on_field(Field, Dir, MovedField) :-
  field(Used, _) = Field,
  tiles_moves(Field, Dir, Moves),
  findall(Tile, (
    member(Source, Used),
    member(move(Source, Dest), Moves),
    (Tile = Source; Tile = Dest)),
    TilesOnMovesRaw
  ),
  sort(TilesOnMovesRaw, TilesOnMoves),
  ord_symdiff(Used, TilesOnMoves, MovedUsed),
  empty_field([4, 4], EmptyField),
  add_tiles(EmptyField, MovedUsed, MovedField).

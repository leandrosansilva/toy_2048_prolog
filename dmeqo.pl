% Vim, this is Prolog!

% helper
next_value(N, M) :- var(N), N is M - 1, !.
next_value(N, M) :- var(M), M is N + 1.

empty_field(Dimension, field(Dimension, [], Empty)) :-
  [H, W] = Dimension,
  next_value(MaxX, W),
  next_value(MaxY, H),
  findall(
    [X, Y], (
      between(0, MaxX, X),
      between(0, MaxY, Y)),
    GenEmpty),
  sort(GenEmpty, Empty).

field_properties(field(_, Used, Empty), Used, Empty).

% it's private because in the real game
% only tile with value 2 or 4 can be added
add_tile_private(Field, Tile , NewField) :-
  add_tiles(Field, [Tile], NewField).

add_tile(Field, Tile, NewField) :-
  tile(_, _, Value) = Tile,
  member(Value, [2, 4]), !,
  add_tile_private(Field, Tile, NewField).

add_tiles(field(Dimension, Used, Empty), TilesRaw, field(Dimension, NewUsed, NewEmpty)) :-
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

merge_tiles(field(_, Used, Empty), Tile1, Tile2, Merged, Dir) :-
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
  next_value(PrevBegin, Begin),
  next_value(End, SuccEnd),
  between(Begin, End, Y).

between_tiles(Dir, [X1, Y], [X2, Y], [X, Y]) :-
  member(Dir, [left, right]),
  msort([X1, X2], [PrevBegin, SuccEnd]),
  next_value(PrevBegin, Begin),
  next_value(End, SuccEnd),
  between(Begin, End, X).

% FIXME: this predicate is way too complex :-(
merge_tiles_on_field(Field, Dir, MergedField) :-
  field(Dimension, Used, _) = Field,
  find_mergeables(Field, Dir, Mergeables),
  foldl(merge_tiles_on_field_util, Mergeables, [], AllNewTilesRaw),
  sort(AllNewTilesRaw, AllNewTiles),
  ord_symdiff(Used, AllNewTiles, MergedUsed),
  empty_field(Dimension, EmptyField),
  add_tiles(EmptyField, MergedUsed, MergedField).

merge_tiles_on_field_util(mergeable(Tile1, Tile2, Tile3), Acc, NewAcc) :-
  (member(Tile1, Acc); member(Tile2, Acc)), NewAcc = Acc, !;
  NewAcc = [Tile1, Tile2, Tile3|Acc].

tiles_moves(field(Dimension, Used, Empty), Dir, Moves) :-
  findall(
    move(Source, Dest),(
      member(Source, Used),
      new_tile_position(Dimension, Source, Dir, Empty, Dest),
      Source \= Dest),
    Moves).

% TODO: Refactor new_tile_position/5
new_tile_position([_, W], tile(X1, Y, V), right, Empty, tile(X2, Y, V)) :-
  next_value(LastColumn, W),
  next_value(X1, NextColumn),
  aggregate_all(count, (
    between(NextColumn, LastColumn, Column),
    ord_memberchk([Column, Y], Empty)),
    NumberOfSpaces),
  X2 is X1 + NumberOfSpaces.

new_tile_position(_, tile(X1, Y, V), left, Empty, tile(X2, Y, V)) :-
  next_value(PrevColumn, X1),
  aggregate_all(count, (
    between(0, PrevColumn, Column),
    ord_memberchk([Column, Y], Empty)),
    NumberOfSpaces),
  X2 is X1 - NumberOfSpaces.

new_tile_position(_, tile(X, Y1, V), up, Empty, tile(X, Y2, V)) :-
  next_value(PrevRow, Y1),
  aggregate_all(count, (
    between(0, PrevRow, Row),
    ord_memberchk([X, Row], Empty)),
    NumberOfSpaces),
  Y2 is Y1 - NumberOfSpaces.

new_tile_position([H, _], tile(X, Y1, V), down, Empty, tile(X, Y2, V)) :-
  next_value(LastRow, H),
  next_value(Y1, NextRow),
  aggregate_all(count, (
    between(NextRow, LastRow, Row),
    ord_memberchk([X, Row], Empty)),
    NumberOfSpaces),
  Y2 is Y1 + NumberOfSpaces.

move_tiles(Field, Dir, MovedField) :-
  merge_tiles_on_field(Field, Dir, MergedField),
  move_tiles_on_field(MergedField, Dir, MovedField).

% FIXME: I know, it's copy-paste. I'll refactor it later...
move_tiles_on_field(Field, Dir, MovedField) :-
  field(Dimension, Used, _) = Field,
  tiles_moves(Field, Dir, Moves),
  findall(Tile, (
    member(Source, Used),
    member(move(Source, Dest), Moves),
    (Tile = Source; Tile = Dest)),
    TilesOnMovesRaw
  ),
  sort(TilesOnMovesRaw, TilesOnMoves),
  ord_symdiff(Used, TilesOnMoves, MovedUsed),
  empty_field(Dimension, EmptyField),
  add_tiles(EmptyField, MovedUsed, MovedField).

generate_new_random_tile(field(_, _, Empty), tile(X, Y, Value)) :-
  random_member(Value, [2, 4]),
  random_member([X, Y], Empty).

print_field(field([H, W], Used, _), String) :-
  next_value(LastRow, H),
  next_value(LastColumn, W),
  findall(Line, (
    between(0, LastRow, Y),
    print_field_line(Used, Y, LastColumn, Line)),
    LinesList),
  flatten(LinesList, Codes),
  string_codes(String, Codes).

print_field_line(Used, Y, LastColumn, Line) :-
  findall(Tile, (
      between(0, LastColumn, X),
      print_tile(Used, X, Y, Tile)),
    LinePayload, `|\n`),
  flatten(LinePayload, Line).

print_tile(Used, X, Y, Tile) :-
  member(tile(X, Y, Value), Used), !,
  format(string(S), '|~|~` t~d~4+', [Value]),
  string_codes(S, Tile).

print_tile(_, _, _, `|    `).

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
    MergeablesRaw),

  list_to_ord_set(MergeablesRaw, Mergeables).

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

merge_tiles_on_field(Field, Dir, field(MergedUsed, MergedEmpty)) :-
  field(Used, Empty) = Field,
  find_mergeables(Field, Dir, Mergeables),

  findall(Tile, (
    member(mergeable(Tile, _, _), Mergeables);
    member(mergeable(_, Tile, _), Mergeables);
    member(mergeable(_, _, Tile), Mergeables)
  ), AllNewTilesRaw),
  list_to_ord_set(AllNewTilesRaw, AllNewTiles),
  ord_symdiff(Used, AllNewTiles, MergedUsed),

  findall([X, Y], (
    member(mergeable(tile(NX, NY, _), tile(X, Y, _), tile(NX, NY, _)), Mergeables);
    member(mergeable(tile(X, Y, _), tile(NX, NY, _), tile(NX, NY, _)), Mergeables)
  ), AllNewPositionsRaw),
  list_to_ord_set(AllNewPositionsRaw, AllNewPositions),
  ord_union(Empty, AllNewPositions, MergedEmpty).

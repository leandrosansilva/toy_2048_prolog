% prolog

:- load_files(dmeqo).

:- use_module(library(plunit)).

:- begin_tests(dmeqo_tests).

test('create empty fields 3,3') :-
  empty_field([3, 3], field(UsedTiles, EmptyTiles)),
  length(UsedTiles, 0),
  length(EmptyTiles, 9).

test('create empty fields 4,5') :-
  empty_field([4, 5], field(UsedTiles, EmptyTiles)),
  length(UsedTiles, 0),
  length(EmptyTiles, 20).

test('create empty fields 4,5 and adds one tile') :-
  empty_field([4, 5], Field),
  add_tile(Field, tile(0, 0, 2), field([tile(0, 0, 2)], EmptyTiles)),
  length(EmptyTiles, 19).

test('only tiles with value 2 or 4 can be added') :-
  empty_field([4, 4], Field),
  add_tile(Field, tile(1, 1, 2), NewField1),
  add_tile(NewField1, tile(1, 1, 4), NewField2),
  not(add_tile(NewField2, tile(1, 1, 16), _)).

test('tile evolution') :-
  next_tile_value(2, 4),
  next_tile_value(4, 8),
  next_tile_value(8, 16),
  next_tile_value(16, 32).

test('merge two tiles') :-
  merge_tiles(tile(1, 2, 2), tile(3, 2, 2), right, tile(3, 2, 4)),
  merge_tiles(tile(3, 2, 2), tile(1, 2, 2), right, tile(3, 2, 4)),

  merge_tiles(tile(1, 2, 2), tile(3, 2, 2), left, tile(1, 2, 4)),
  merge_tiles(tile(3, 2, 2), tile(1, 2, 2), left, tile(1, 2, 4)),

  merge_tiles(tile(3, 1, 4), tile(3, 2, 4), up, tile(3, 1, 8)),
  merge_tiles(tile(3, 2, 4), tile(3, 1, 4), up, tile(3, 1, 8)),

  merge_tiles(tile(3, 2, 4), tile(3, 1, 4), down, tile(3, 2, 8)),
  merge_tiles(tile(3, 2, 4), tile(3, 1, 4), down, tile(3, 2, 8)),

  % cannot merge non-related tiles
  not(merge_tiles(tile(3, 2, 4), tile(2, 1, 4), down, Merged)),
  not(merge_tiles(tile(3, 2, 4), tile(2, 1, 4), up, Merged)),
  not(merge_tiles(tile(3, 2, 4), tile(2, 1, 4), left, Merged)),
  not(merge_tiles(tile(3, 2, 4), tile(2, 1, 4), right, Merged)),

  % cannot merge tiles with different values
  not(merge_tiles(tile(1, 2, 2), tile(3, 2, 8), left, Merged)),
  not(merge_tiles(tile(1, 2, 4), tile(3, 2, 2), right, Merged)),
  not(merge_tiles(tile(3, 1, 16), tile(3, 2, 2), up, Merged)),
  not(merge_tiles(tile(3, 2, 1024), tile(3, 1, 256), down, Merged)).

test('Fill field with several tiles (dev helper)') :-
  Tiles = [tile(0, 0, 2), tile(1, 0, 4), tile(0, 1, 2)],
  length(Tiles, LengthTiles),
  empty_field([3, 7], Field),
  add_tiles(Field, Tiles, field(UsedTiles, EmptyTiles)),
  length(UsedTiles, LengthTiles),
  length(EmptyTiles, 18).

test('Find two mergeable tiles') :-
  empty_field([4, 4], EmptyField),
  find_mergeables(EmptyField, up, []),
  add_tiles(EmptyField, [tile(1, 0, 2), tile(1, 2, 2)], Field),
  find_mergeables(Field, up, Mergeables),
  Mergeables = [mergeable(tile(1, 0, 2), tile(1, 2, 2), tile(1, 0, 4))].

test('Mmerge only non-interleaved tiles when moving up') :-
  empty_field([5, 4], EmptyField),
  Tiles = [tile(1, 0, 2), tile(1, 1, 4), tile(1, 3, 2), tile(1, 4, 4), tile(2, 1, 8), tile(2, 3, 8)],
  add_tiles(EmptyField, Tiles, Field),
  find_mergeables(Field, up, [mergeable(tile(2, 1, 8), tile(2, 3, 8), tile(2, 1, 16))]).

test('Merge only non-interleaved tiles when moving down') :-
  empty_field([5, 4], EmptyField),
  Tiles = [tile(1, 0, 2), tile(1, 1, 4), tile(1, 3, 2), tile(1, 4, 4), tile(2, 1, 8), tile(2, 3, 8)],
  add_tiles(EmptyField, Tiles, Field),
  find_mergeables(Field, down, [mergeable(tile(2, 1, 8), tile(2, 3, 8), tile(2, 3, 16))]).

test('Merge only non-interleaved tiles when moving left') :-
  empty_field([5, 4], EmptyField),
  Tiles = [
    tile(0, 0, 2), tile(2, 0, 2), tile(3, 0, 32), 
    tile(2, 1, 16), tile(3, 1, 16), tile(0, 2, 4), 
    tile(2, 2, 8), tile(3, 2, 4), tile(1, 3, 2)],
  add_tiles(EmptyField, Tiles, Field),
  find_mergeables(Field, left, Mergeables),
  sort([
      mergeable(tile(2, 1, 16), tile(3, 1, 16), tile(2, 1, 32)),
      mergeable(tile(0, 0, 2), tile(2, 0, 2), tile(0, 0, 4))], 
    Mergeables).

test('Merge only non-interleaved tiles when moving right') :-
  empty_field([5, 4], EmptyField),
  Tiles = [
    tile(0, 0, 2), tile(2, 0, 2), tile(3, 0, 32), 
    tile(2, 1, 16), tile(3, 1, 16), tile(0, 2, 4), 
    tile(2, 2, 8), tile(3, 2, 4), tile(1, 3, 2)],
  add_tiles(EmptyField, Tiles, Field),
  find_mergeables(Field, right, Mergeables),
  sort([
      mergeable(tile(2, 1, 16), tile(3, 1, 16), tile(3, 1, 32)),
      mergeable(tile(0, 0, 2), tile(2, 0, 2), tile(2, 0, 4))], 
    Mergeables).

test('When 3 are mergeable, merge two and let one alone') :-
  empty_field([4, 4], EmptyField),
  Tiles = [tile(1, 1, 8), tile(2, 1, 8), tile(3, 1, 8)], 
  add_tiles(EmptyField, Tiles, Field),
  find_mergeables(Field, right, [mergeable(tile(2, 1, 16), tile(3, 1, 16), tile(3, 1, 32))]).

test('Merge tiles on-field') :-
  empty_field([4, 4], EmptyField),
  Tiles = [
    tile(0, 0, 2), tile(2, 0, 2), tile(3, 0, 32), 
    tile(2, 1, 16), tile(3, 1, 16), tile(0, 2, 4), 
    tile(2, 2, 8), tile(3, 2, 4), tile(1, 3, 2)],
  add_tiles(EmptyField, Tiles, Field),
  merge_tiles_on_field(Field, right, MergedField),

  AfterMergedTiles = [
    tile(2, 0, 4), tile(3, 0, 32), 
    tile(3, 1, 32), tile(0, 2, 4),
    tile(2, 2, 8), tile(3, 2, 4), tile(1, 3, 2)],

  add_tiles(EmptyField, AfterMergedTiles, MergedField).
  
:- end_tests(dmeqo_tests).

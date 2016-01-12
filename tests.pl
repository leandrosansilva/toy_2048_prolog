% prolog

:- load_files(dmeqo).

:- use_module(library(plunit)).

:- begin_tests(dmeqo_tests).

test('create empty fields 3,3') :-
  empty_field([3, 3], EmptyField),
  field_properties(EmptyField, UsedTiles, EmptyTiles),
  length(UsedTiles, 0),
  length(EmptyTiles, 9).

test('create empty fields 4,5') :-
  empty_field([4, 5], EmptyField),
  field_properties(EmptyField, UsedTiles, EmptyTiles),
  length(UsedTiles, 0),
  length(EmptyTiles, 20).

test('create empty fields 4,5 and adds one tile') :-
  empty_field([4, 5], Field),
  add_tile(Field, tile(0, 0, 2), NewField),
  field_properties(NewField, [tile(0, 0, 2)], EmptyTiles),
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
  add_tiles(Field, Tiles, NewField),
  field_properties(NewField, UsedTiles, EmptyTiles),
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
  find_mergeables(Field, left, [
    mergeable(tile(0, 0, 2), tile(2, 0, 2), tile(0, 0, 4)),
    mergeable(tile(2, 1, 16), tile(3, 1, 16), tile(2, 1, 32))]).

test('Merge only non-interleaved tiles when moving right') :-
  empty_field([5, 4], EmptyField),
  Tiles = [
    tile(0, 0, 2), tile(2, 0, 2), tile(3, 0, 32),
    tile(2, 1, 16), tile(3, 1, 16), tile(0, 2, 4),
    tile(2, 2, 8), tile(3, 2, 4), tile(1, 3, 2)],
  add_tiles(EmptyField, Tiles, Field),
  find_mergeables(Field, right, [
    mergeable(tile(0, 0, 2), tile(2, 0, 2), tile(2, 0, 4)),
    mergeable(tile(2, 1, 16), tile(3, 1, 16), tile(3, 1, 32))]).

test('When 3 are mergeable, merge two and let one alone') :-
  empty_field([4, 4], EmptyField),
  Tiles = [tile(1, 1, 8), tile(2, 1, 8), tile(3, 1, 8)],
  add_tiles(EmptyField, Tiles, Field),
  find_mergeables(Field, right, [mergeable(tile(2, 1, 16), tile(3, 1, 16), tile(3, 1, 32))]).

test('When 4 inline are mergeable, merge two groups of two') :-
  empty_field([4, 4], EmptyField),
  Tiles = [tile(0, 1, 8), tile(1, 1, 8), tile(2, 1, 8), tile(3, 1, 8)],
  add_tiles(EmptyField, Tiles, Field),
  find_mergeables(Field, right, [
    mergeable(tile(0, 1, 16), tile(1, 1, 16), tile(1, 1, 32)), 
    mergeable(tile(2, 1, 16), tile(3, 1, 16), tile(3, 1, 32))]).

test('Merge tiles on-field on moving right') :-
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

test('Obtain tiles moves right on an already merged field') :-
  empty_field([4, 4], EmptyField),
  Tiles = [
    tile(2, 0, 4), tile(3, 0, 32),
    tile(3, 1, 32), tile(0, 2, 4),
    tile(2, 2, 8), tile(3, 2, 4), tile(1, 3, 2)],
  add_tiles(EmptyField, Tiles, Field),
  tiles_moves(Field, right, [
    move(tile(0, 2, 4), tile(1, 2, 4)),
    move(tile(1, 3, 2), tile(3, 3, 2))
  ]).

test('Obtain tiles moves left on an already merged field') :-
  empty_field([4, 4], EmptyField),
  Tiles = [
    tile(1, 0, 2), tile(2, 0, 4), tile(3, 0, 8)],
  add_tiles(EmptyField, Tiles, Field),
  tiles_moves(Field, left, [
    move(tile(1, 0, 2), tile(0, 0, 2)),
    move(tile(2, 0, 4), tile(1, 0, 4)),
    move(tile(3, 0, 8), tile(2, 0, 8))
  ]).

test('Merge and move field right - simple') :-
  empty_field([4, 4], EmptyField),
  Tiles = [
    tile(0, 0, 4), tile(2, 3, 32)],
  add_tiles(EmptyField, Tiles, Field),
  move_tiles(Field, right, MovedField),
  AfterMoveTiles = [
    tile(3, 0, 4), tile(3, 3, 32)],
  add_tiles(EmptyField, AfterMoveTiles, MovedField).

test('Merge and move tiles right - complex') :-
  empty_field([4, 4], EmptyField),
  Tiles = [
    tile(0, 0, 2), tile(2, 0, 2), tile(3, 0, 32),
    tile(2, 1, 16), tile(3, 1, 16),
    tile(0, 2, 4), tile(2, 2, 8), tile(3, 2, 4),
    tile(1, 3, 2)],
  add_tiles(EmptyField, Tiles, Field),
  move_tiles(Field, right, MovedField),
  AfterMoveTiles = [
    tile(2, 0, 4), tile(3, 0, 32),
    tile(3, 1, 32), tile(1, 2, 4),
    tile(2, 2, 8), tile(3, 2, 4), tile(3, 3, 2)],
  add_tiles(EmptyField, AfterMoveTiles, MovedField).

test('Merge and move tiles up - complex') :-
  empty_field([4, 4], EmptyField),
  Tiles = [
    tile(0, 0, 2), tile(2, 0, 2), tile(3, 0, 32),
    tile(2, 1, 16), tile(3, 1, 16),
    tile(0, 2, 4), tile(2, 2, 8), tile(3, 2, 4),
    tile(1, 3, 2)],
  add_tiles(EmptyField, Tiles, Field),
  move_tiles(Field, up, MovedField),
  AfterMoveTiles = [
    tile(0, 0, 2), tile(1, 0, 2), tile(2, 0, 2), tile(3, 0, 32),
    tile(0, 1, 4), tile(2, 1, 16), tile(3, 1, 16),
    tile(2, 2, 8), tile(3, 2, 4)],
  add_tiles(EmptyField, AfterMoveTiles, MovedField).

test('Merge and move tiles down - complex') :-
  empty_field([4, 4], EmptyField),
  Tiles = [
    tile(0, 0, 2), tile(2, 0, 2), tile(3, 0, 32),
    tile(2, 1, 16), tile(3, 1, 16),
    tile(0, 2, 4), tile(2, 2, 8), tile(3, 2, 4),
    tile(1, 3, 2)],
  add_tiles(EmptyField, Tiles, Field),
  move_tiles(Field, down, MovedField),
  AfterMoveTiles = [
    tile(2, 1, 2), tile(3, 1, 32),
    tile(0, 2, 2), tile(2, 2, 16), tile(3, 2, 16),
    tile(0, 3, 4), tile(1, 3, 2), tile(2, 3, 8), tile(3, 3, 4)],
  add_tiles(EmptyField, AfterMoveTiles, MovedField).

test('Merge and move tiles - buggy case') :-
  empty_field([2, 1], EmptyField),
  add_tiles(EmptyField, [tile(0, 1, 2)], Field),
  % up
  move_tiles(Field, up, UpMovedField),
  add_tiles(EmptyField, [tile(0, 0, 2)], UpMovedField),
  % down
  move_tiles(Field, down, DownMovedField),
  add_tiles(EmptyField, [tile(0, 1, 2)], DownMovedField),
  % left
  move_tiles(Field, left, LeftMovedField),
  add_tiles(EmptyField, [tile(0, 1, 2)], LeftMovedField),
  % right
  move_tiles(Field, right, RightMovedField),
  add_tiles(EmptyField, [tile(0, 1, 2)], RightMovedField).

test('Generate random new tile') :-
  empty_field([4, 4], EmptyField),
  Tiles = [
    tile(0, 0, 2), tile(2, 0, 2), tile(3, 0, 32),
    tile(2, 1, 16), tile(3, 1, 16),
    tile(0, 2, 4), tile(2, 2, 8), tile(3, 2, 4),
    tile(1, 3, 2)],
  add_tiles(EmptyField, Tiles, Field),
  field_properties(Field, _, Empty),
  generate_new_random_tile(Field, tile(X, Y, Value)),
  member(Value, [2, 4]),
  member([X, Y], Empty).

test('Print empty field') :-
  empty_field([4, 4], Field),
  print_field(Field, "|    |    |    |    |\n|    |    |    |    |\n|    |    |    |    |\n|    |    |    |    |\n").

test('Print field with some elements') :-
  empty_field([4, 4], EmptyField),
  add_tiles(EmptyField, [
    tile(0, 0, 2), tile(3, 0, 128),
    tile(2, 2, 1024),
    tile(0, 3, 16), tile(3, 3, 2048)], Field),
  print_field(Field, "|   2|    |    | 128|\n|    |    |    |    |\n|    |    |1024|    |\n|  16|    |    |2048|\n").

:- end_tests(dmeqo_tests).

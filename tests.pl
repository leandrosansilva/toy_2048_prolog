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
  merge_tiles(tile(1, 2, 2), tile(3, 2, 2), left, tile(3, 2, 4)),
  merge_tiles(tile(3, 2, 2), tile(1, 2, 2), left, tile(3, 2, 4)),

  merge_tiles(tile(1, 2, 2), tile(3, 2, 2), right, tile(1, 2, 4)),
  merge_tiles(tile(3, 2, 2), tile(1, 2, 2), right, tile(1, 2, 4)),

  merge_tiles(tile(3, 1, 4), tile(3, 2, 4), up, tile(3, 1, 8)),
  merge_tiles(tile(3, 2, 4), tile(3, 1, 4), up, tile(3, 1, 8)),

  merge_tiles(tile(3, 2, 4), tile(3, 1, 4), down, tile(3, 2, 8)),
  merge_tiles(tile(3, 2, 4), tile(3, 1, 4), down, tile(3, 2, 8)),

  % cannot merge non-related tiles (diagonal)
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

test('Find merging pairs') :-
  empty_field([4, 4], EmptyField),
  find_merging_pairs(EmptyField, []).
  %Tiles = [tile(1, 0, 2), tile(1, 0, 2), tile(0, 1, 2)i],
  %add_tiles(EmptyField, Tiles, Field),


%test('Slide field with a single element to the right') :-
%  empty_field([4, 5], Field),
%  add_tile(Field, [1, 2], NewField),
%  move_tiles(NewField, left, field([tile(4, 2)], Empty)),
%  length(Empty, 19).

:- end_tests(dmeqo_tests).

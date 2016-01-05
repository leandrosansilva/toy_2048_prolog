% prolog

:- load_files(dmeqo).

:- use_module(library(plunit)).

:- begin_tests(dmeqo_tests).

test('create empty fields 3,3') :-
  empty_field([3, 3], field(UsedPositions, EmptyPositions)),
  length(UsedPositions, 0),
  length(EmptyPositions, 9).
  
test('create empty fields 4,5') :-
  empty_field([4, 5], field(UsedPositions, EmptyPositions)),
  length(UsedPositions, 0),
  length(EmptyPositions, 20).

test('create empty fields 4,5 and adds one tile') :-
  empty_field([4, 5], Field),
  add_tile(Field, [0, 0], field([tile(0, 0, _)], EmptyPositions)),
  length(EmptyPositions, 19).
  
:- end_tests(dmeqo_tests).

% this is prolog!

:- load_files(dmeqo).

main(_) :-
  empty_field([4, 4], EmptyField),
  run_game(EmptyField).

run_game(Field) :-
  generate_new_random_tile(Field, Tile),
  add_tile(Field, Tile, AddedTileField),
  move_field_from_user_input(AddedTileField, MovedField),
  run_game(MovedField).

run_game(_) :-
  write("Game Over!"), nl.

move_field_from_user_input(Field, NewField) :-
  write('\e[H\e[2J'), % clear screen
  print_field(Field, S),
  write(S),
  read_move_direction(Direction), !,
  move_tiles(Field, Direction, MovedField),
  field_properties(MovedField, _, Empty),
  not(length(Empty, 0)),
  (
    Field = MovedField,
    move_field_from_user_input(MovedField, NewField), !;
    NewField = MovedField
  ).

% read_move_direction(Direction) :- 
%   random_member(Direction, [right, down, left, up]), !.

read_move_direction(Direction) :-
  get_single_char(27), % ESC
  get_single_char(91), % arrows
  get_single_char(Arrow),
  (
    Arrow = 65, Direction = up;
    Arrow = 66, Direction = down;
    Arrow = 67, Direction = right;
    Arrow = 68, Direction = left
  ).

% Read again otherwise
read_move_direction(Direction) :-
  read_move_direction(Direction).

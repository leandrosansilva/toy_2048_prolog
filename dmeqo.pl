% Vim, this is Prolog!

empty_field([H, W], field([], Empty)) :-
  succ(MaxX, W),
  succ(MaxY, H),
  findall(
    pos(X, Y), (
      between(0, MaxX, X), 
      between(0, MaxY, Y)),
    GenEmpty),
  list_to_ord_set(GenEmpty, Empty).

% it's private because in the real game
% only tile with value 2 can be added
add_tile_private(field(Used, Empty), [X, Y, TileValue], field(NewUsed, NewEmpty)) :-
  ord_add_element(Used, tile(X, Y, TileValue), NewUsed),
  ord_del_element(Empty, pos(X, Y), NewEmpty).

add_tile(Field, [X, Y], NewField) :- 
  add_tile_private(Field, [X, Y, 2], NewField).

add_tile_private(field(Used, Empty), [X, Y, TileValue], field(NewUsed, NewEmpty)) :-
  ord_add_element(Used, tile(X, Y, TileValue), NewUsed),
  ord_del_element(Empty, pos(X, Y), NewEmpty).
 

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

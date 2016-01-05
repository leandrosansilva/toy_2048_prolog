% Vim, this is Prolog!

empty_field([H, W], field([], Empty)) :-
  MaxX is W - 1,
  MaxY is H - 1,
  findall(X, between(0, MaxX, X), Xs),
  findall(Y, between(0, MaxY, Y), Ys), 
  findall(pos(XX, YY), (member(XX, Xs), member(YY, Ys)), GenEmpty),
  list_to_ord_set(GenEmpty, Empty).

add_tile(field(Used, Empty), [X, Y], field(NewUsed, NewEmpty)) :-
  tile(X, Y, _) = Tile,
  ord_add_element(Used, Tile, NewUsed),
  ord_del_element(Empty, pos(X, Y), NewEmpty).

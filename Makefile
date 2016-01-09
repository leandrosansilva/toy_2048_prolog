all: clean
	swipl --nodebug -g true -O -q --toplevel=main --stand_alone=true -o main -c main.pl

clean:
	rm main -f

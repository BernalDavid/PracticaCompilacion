CFLAGS=-Wall

all: parser prueba

clean:
	rm parser.cpp parser.hpp parser tokens.cpp *~ 

parser.cpp: parser.y
	bison -d -o $@ $^

parser.hpp: parser.cpp

tokens.cpp: tokens.l parser.hpp
	lex -o $@ $^

parser: parser.cpp main.cpp tokens.cpp
	g++ $(CFLAGS) -o $@ *.cpp 

prueba:  parser ./pruebas/pruebaBuena1.in ./pruebas/pruebaBuena2.in ./pruebas/pruebaMala1.in ./pruebas/pruebaMala2.in
	./parser <./pruebas/pruebaBuena1.in
	./parser <./pruebas/pruebaBuena2.in
	./parser <./pruebas/pruebaMala1.in
	./parser <./pruebas/pruebaMala2.in 


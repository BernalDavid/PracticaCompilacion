%{
   #include <stdio.h>
   #include <iostream>
   #include <vector>
   #include <string>
   using namespace std; 

   extern int yylex();
   extern int yylineno;
   extern char *yytext;
   void yyerror (const char *msg) {
     printf("line %d: %s at '%s'\n", yylineno, msg, yytext) ;
   }

%}

/* 
   qué atributos tienen los tokens 
*/
%union {
    string *str ; 
}

/* 
   declaración de tokens. Esto debe coincidir con tokens.l 
*/
%token <str> RDEF RMAIN RBEGIN RENDPROGRAM RIF RELSE RWHILE RFOREVER RBREAK RCONTINUE RREAD RPRINT RLET RIN RINTEGER RFLOAT
%token <str> TSEMIC TASSIG TDOSPUNTOS TCOMA
%token <str> TIDENTIFIER TINTEGER TDOUBLE
%token <str> TLLAVEI TLLAVED TPARENI TPAREND TAND
%token <str> TEQUAL TMAYOR TMENOR TMAYOREQ TMENOREQ TNOTEQUAL
%token <str> TPLUS TMINUS TMUL TDIV


%type <str> programa
%type <str> bloque_ppl
%type <str> bloque
//%type <str> decl_bl
%type <str> declaraciones
%type <str> lista_de_ident
//%type <str> resto_lista_id
%type <str> tipo
//%type <str> decl_de_subprogs
%type <str> decl_de_subprograma
//%type <str> argumentos
%type <str> lista_de_param
//%type <str> clase_par
//%type <str> resto_lis_de_param
//%type <str> lista_de_sentencias
%type <str> sentencia
%type <str> variable
%type <str> expresion

//Prioridad y asociatividad de los operadores
%nonassoc TASSIG TNOTEQUAL TMENOR TMENOREQ TMAYOR TMAYOREQ
%left TPLUS TMINUS
%left TMUL TDIV

%start programa
%%

programa : RDEF RMAIN TPARENI TPAREND TDOSPUNTOS  
           bloque_ppl
         ;

bloque_ppl : decl_bl TLLAVEI
            decl_de_subprogs
            lista_de_sentencias
            TLLAVED
           ;

bloque : TLLAVEI
         lista_de_sentencias
         TLLAVED
       ;

decl_bl : RLET declaraciones RIN
        | /* empty */
        ;

declaraciones : declaraciones TSEMIC lista_de_ident TDOSPUNTOS tipo
              | lista_de_ident TDOSPUNTOS tipo
              ;

lista_de_ident : TIDENTIFIER resto_lista_id
               ;

resto_lista_id : TCOMA TIDENTIFIER resto_lista_id
               | /* empty */
               ;

tipo : RINTEGER
     | RFLOAT
     ;

decl_de_subprogs : decl_de_subprograma decl_de_subprogs
                 | /* empty */
                 ;

decl_de_subprograma : RDEF TIDENTIFIER argumentos TDOSPUNTOS bloque_ppl
                    ;

argumentos : TPARENI lista_de_param TPAREND
           | /* empty */
           ;

lista_de_param : lista_de_ident TDOSPUNTOS clase_par tipo resto_lis_de_param
               ;

clase_par : /* empty */
          | TAND
          ;

resto_lis_de_param : TSEMIC lista_de_ident TDOSPUNTOS clase_par tipo resto_lis_de_param
                    | /* empty */
                    ;

lista_de_sentencias : sentencia lista_de_sentencias
                    | /* empty */
                    ;

sentencia : variable TASSIG expresion TSEMIC
          | RIF expresion TDOSPUNTOS bloque
          | RWHILE expresion TDOSPUNTOS bloque RELSE TDOSPUNTOS bloque
          | RFOREVER TDOSPUNTOS bloque
          | RBREAK RIF expresion TSEMIC
          | RCONTINUE TSEMIC
          | RREAD TPARENI variable TPAREND TSEMIC
          | RPRINT TPARENI expresion TPAREND TSEMIC
          ;

variable : TIDENTIFIER
         ;

expresion : expresion TEQUAL expresion
          | expresion TMAYOR expresion
          | expresion TMENOR expresion
          | expresion TMAYOREQ expresion
          | expresion TMENOREQ expresion
          | expresion TNOTEQUAL expresion
          | expresion TPLUS expresion
          | expresion TMINUS expresion
          | expresion TMUL expresion
          | expresion TDIV expresion
          | TIDENTIFIER
          | TINTEGER
          | TDOUBLE
          | TPARENI expresion TPAREND
          ;
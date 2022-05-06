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

/* Funciones que se usan*/
 estructuraExpresion comparar(std::string &s1, std::string &s2, std::string &s3) ;
 estructuraExpresion operar(std::string &s1, std::string &s2, std::string &s3) ;
/* 
   qué atributos tienen los tokens 
*/
%union {
    string *str ; 
    estructuraExpresion *expr;
    estructuraSentencia *sent;
    
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
//%type <sent> lista_de_sentencias
%type <str> sentencia
%type <str> variable
%type <expr> expresion

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
            {
               $$= new estructuraSentencia;
               codigo.anadirInstruccion(*$1 + " := " + $3->str + ";") ; 
               $$->exits: * new vector<int>;
               // o exits.clear() * new vector<int>??
               $$->tipo = "asignacion";
               delete $1 ; delete $3;
            }
          | RIF expresion TDOSPUNTOS M bloque M
            {
               $$ = new estructuraSentencia;
	      	   codigo.completarInstrucciones($2->trues,$4);
    	  	      codigo.completarInstrucciones($2->falses,$6);
	      	   $$->exits = $5->exits;
               delete $2 ;
            }
          | RWHILE M expresion TDOSPUNTOS M bloque N RELSE TDOSPUNTOS M bloque
            {
               $$ = new estructuraSentencia;
	      	   codigo.completarInstrucciones($3->trues,$5);
    	  	      codigo.completarInstrucciones($3->falses,$10);

               //esto no se lo que es, supuestamente para el N.next??
               vector<int> tmp1; 
               tmp1.push_back($7);
               codigo.completarInstrucciones(tmp1, $2);
               codigo.completarInstrucciones($6->exits, $7+1);
               $$->exits.clear();
               /* No se si es necesario
                  $$->exits = $11->exits; */
               delete $4;
            }
          | RFOREVER TDOSPUNTOS M bloque M 
            {
               $$ = new estructuraSentencia;
               codigo.anadirInstruccion("goto " + $3);
               codigo.completarInstrucciones($4, codigo.obtenRef());
               $$->exits= * new vector<int>;
            }
          | RBREAK RIF expresion TSEMIC
            {
               $$ = new estructuraSentencia;
               codigo.completarInstrucciones($3->falses, codigo.obtenRef());
               $$->exits = $3->trues;
               delete $2;
            }
          | RCONTINUE TSEMIC
            /*{

            }*/
          | RREAD TPARENI variable TPAREND TSEMIC
            {
               $$ = new estructuraSentencia;
					$$->exits = * new vector<int>;
					codigo.anadirInstruccion("read "+ *$3 + ";");
            }
          | RPRINT TPARENI expresion TPAREND TSEMIC
            {
               {$$ = new sentenciastruct;
					$$->exits = * new vector<int>;
					codigo.anadirInstruccion("write "+ $3->str + ";");
					codigo.anadirInstruccion("writeln;");
            }
          ;

variable : TIDENTIFIER
            {
               $$= $1;
            }
         ;

expresion : expresion TEQUAL expresion
            {
               $$= new estructuraExpresion;
               $$->tipo = "comparación";
               *$$ = comparar($1->str,*$2,$3->str); 

               delete $1; delete $3; 
            }
          | expresion TMAYOR expresion
            {
               $$= new estructuraExpresion;
               $$->tipo = "comparación";
               *$$ = comparar($1->str,*$2,$3->str); 

               delete $1; delete $3; 
            }
          | expresion TMENOR expresion
            {
               $$= new estructuraExpresion;
               $$->tipo = "comparación";
               *$$ = comparar($1->str,*$2,$3->str); 

               delete $1; delete $3; 
            }
          | expresion TMAYOREQ expresion
            {
               $$= new estructuraExpresion;
               $$->tipo = "comparación";
               *$$ = comparar($1->str,*$2,$3->str); 

               delete $1; delete $3; 
            }
          | expresion TMENOREQ expresion
            {
               $$= new estructuraExpresion;
               $$->tipo = "comparación";
               *$$ = comparar($1->str,*$2,$3->str); 

               delete $1; delete $3; 
            }
          | expresion TNOTEQUAL expresion
            {
               $$= new estructuraExpresion;
               $$->tipo = "comparación";
               *$$ = comparar($1->str,*$2,$3->str); 

               delete $1; delete $3; 
            }
          | expresion TPLUS expresion
            {
               $$= new estructuraExpresion;
               $$->tipo = "operación aritmética";
               *$$ = operar($1->str,*$2,$3->str); 

               delete $1; delete $3; 
            }
          | expresion TMINUS expresion
            {
               $$= new estructuraExpresion;
               $$->tipo = "operación aritmética";
               *$$ = operar($1->str,*$2,$3->str); 

               delete $1; delete $3; 
            }
          | expresion TMUL expresion
            {
               $$= new estructuraExpresion;
               $$->tipo = "operación aritmética";
               *$$ = operar($1->str,*$2,$3->str); 

               delete $1; delete $3; 
            }
          | expresion TDIV expresion
            {
               $$= new estructuraExpresion;
               $$->tipo = "operación aritmética";
               *$$ = operar($1->str,*$2,$3->str); 

               delete $1; delete $3; 
            }
          | TIDENTIFIER
            {
               $$= new estructuraExpresion;
               $$->n= *$1;
            }
          | TINTEGER
            {
               $$= new estructuraExpresion;
               $$->n= *$1;
               $$->tipo= "Integer";
            }
          | TDOUBLE
            {
               $$= new estructuraExpresion;
               $$->n= *$1;
               $$->tipo= "Double";
            }
          | TPARENI expresion TPAREND
            {
               $$= $2;
            }
          ;
%%

estructuraExpresion comparar(std::string &s1, std::string &s2, std::string &s3) {
  estructuraExpresion tmp ; 

  tmp.trues.push_back(codigo.obtenRef()) ;
  tmp.falses.push_back(codigo.obtenRef()+1) ;

  codigo.anadirInstruccion("if " + s1 + " " + s2 + " " + s3 + " goto") ;
  codigo.anadirInstruccion("goto") ;
  return tmp ;
}

estructuraExpresion operar(std::string &s1, std::string &s2, std::string &s3) {
  estructuraExpresion tmp ; 

  tmp.str = codigo.nuevoId() ;

  codigo.anadirInstruccion(tmp.str + " := " + s1 + " " +  s2 + " " +  s3 + ";") ;
  return tmp ;
}
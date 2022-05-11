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

   #include "Codigo.hpp"
   #include "Exp.hpp"

   /* Funciones que se usan*/
   expresionstruct makecomparison(std::string &s1, std::string &s2, std::string &s3) ;
   expresionstruct makearithmetic(std::string &s1, std::string &s2, std::string &s3) ;
   vector<int> *unir(vector<int> lis1, vector<int> lis2);

   Codigo codigo;
%}

/* 
   qué atributos tienen los tokens 
*/
%union {
    string *str ; 
    expresionstruct *expr;
    sentenciastruct *sen;
    int number;
    vector<string> *lid;
    vector<int> *numlist;
}

/* 
   declaración de tokens. Esto debe coincidir con tokens.l 
*/
%token <str> RDEF RMAIN RIF RELSE RWHILE RFOREVER RBREAK RCONTINUE RREAD RPRINT RLET RIN RINTEGER RFLOAT
%token <str> TSEMIC TASSIG TDOSPUNTOS TCOMA
%token <str> TIDENTIFIER TINTEGER TFLOAT
%token <str> TLLAVEI TLLAVED TPARENI TPAREND TREF
%token <str> TEQUAL TMAYOR TMENOR TMAYOREQ TMENOREQ TNOTEQUAL
%token <str> TPLUS TMINUS TMUL TDIV


%type <str> programa
%type <str> bloque_ppl
%type <sen> bloque
%type <str> decl_bl
%type <str> declaraciones
%type <lid> lista_de_ident
%type <lid> resto_lista_id
%type <str> tipo
//%type <str> decl_de_subprogs
%type <str> decl_de_subprograma
//%type <str> argumentos
%type <lid> lista_de_param
%type <str> clase_par
//%type <str> resto_lis_de_param
%type <sen> lista_de_sentencias
%type <sen> sentencia
%type <str> variable //o tipo <expr>???
%type <expr> expresion
%type <number> M

//Prioridad y asociatividad de los operadores
%nonassoc TASSIG TNOTEQUAL TMENOR TMENOREQ TMAYOR TMAYOREQ
%left TPLUS TMINUS
%left TMUL TDIV

%start programa
%%

programa : RDEF RMAIN TPARENI TPAREND TDOSPUNTOS  
            {
            codigo.anadirInstruccion("proc main");
            }
            bloque_ppl {
            codigo.anadirInstruccion("halt");
            codigo.escribir();
            }
         ;

bloque_ppl  :  decl_bl TLLAVEI
               decl_de_subprogs
               lista_de_sentencias
               TLLAVED
            ;

bloque : TLLAVEI
         lista_de_sentencias
         TLLAVED
         {
         $$ = new sentenciastruct;
         $$->exits = $2->exits;
         $$->continues = $2->continues;
         }
       ;

decl_bl : RLET declaraciones RIN
        | /* empty */
        ;

declaraciones :   declaraciones TSEMIC lista_de_ident TDOSPUNTOS tipo
                  {
                     codigo.anadirDeclaraciones(*$3, *$5);
                  }
              |   lista_de_ident TDOSPUNTOS tipo
                  {
                     codigo.anadirDeclaraciones(*$1, *$3);
                  }
              ;

lista_de_ident :  TIDENTIFIER resto_lista_id
                  {
                     $$ = new vector<string>;
                     $$ = $2; //añadir resto_lista_id
                     $$->insert($$->begin(), *$1); //añadir al principio id
                  }
                  
               ;

resto_lista_id :  TCOMA TIDENTIFIER resto_lista_id
                  {
                     
                     $$  = new vector<string>(*$3);
                     //$$->push_back(*$2);
                     $$->insert($$->begin(), *$2);
                  }
               |  /* empty */
                  {
                     $$ = new vector<string>;
                  }
               ;

tipo :   RINTEGER
         { 
         $$ = new std::string("int");
         }
      |  RFLOAT
         { 
         $$ = new std::string("real");
         }
     ;

decl_de_subprogs : decl_de_subprograma decl_de_subprogs
                 | /* empty */
                 ;

decl_de_subprograma : RDEF TIDENTIFIER { codigo.anadirInstruccion(*$1 + " " + *$2); } // Duda si hay que poner "proc" o "def"
                     argumentos TDOSPUNTOS bloque_ppl { codigo.anadirInstruccion("endproc"); } // Duda si hay que poner en tokens.l o dejar asi
                    ;

argumentos : TPARENI lista_de_param TPAREND
           | /* empty */
           ;

lista_de_param : lista_de_ident TDOSPUNTOS clase_par tipo
                 { codigo.anadirParametros(*$1, *$4, *$3); delete $1; delete $3; delete $4; }
                 resto_lis_de_param
               ;

clase_par : /* empty */
            {
               $$ = new std::string("val");
            }
          | TREF { $$ = new std::string("ref"); }
          ;

resto_lis_de_param : TSEMIC lista_de_ident TDOSPUNTOS clase_par tipo 
                     { codigo.anadirParametros(*$2, *$5, *$4); delete $2; delete $4; delete $5; }
                     resto_lis_de_param
                     | /* empty */
                     ;

lista_de_sentencias : sentencia lista_de_sentencias 
                     {
                        $$ = new sentenciastruct;
                        $$->exits = *unir($1->exits, $2->exits);
                        $$->continues= *unir($1->continues, $2->continues);
                        delete $1; delete $2;
                     } 
                    | /* empty */ 
                     {  
                       $$ = new sentenciastruct;
                       $$->exits = * new vector<int>;
                       $$->continues = * new vector<int>;
                     }
                    ;

sentencia : variable TASSIG expresion TSEMIC
            {
               $$= new sentenciastruct;
               codigo.anadirInstruccion(*$1 + " := " + $3->str + ";") ; 
               $$->exits = * new vector<int>;
               $$->continues = * new vector<int>;
               delete $1 ; delete $3;
            }
          | RIF expresion TDOSPUNTOS M bloque M
            {
               $$ = new sentenciastruct;
	      	   codigo.completarInstrucciones($2->trues,$4);
    	  	      codigo.completarInstrucciones($2->falses,$6);
	      	   $$->exits = $5->exits;
               $$->continues = $5->continues;
               delete $2 ;
            }
          | RWHILE M expresion TDOSPUNTOS M bloque {codigo.anadirInstruccion("goto" + $2);} RELSE TDOSPUNTOS M bloque M
            {
               $$ = new sentenciastruct;
	      	   codigo.completarInstrucciones($3->trues,$5);
    	  	      codigo.completarInstrucciones($3->falses,$10);
               codigo.completarInstrucciones($6->exits, $10);
               codigo.completarInstrucciones($6->continues, $2);
               codigo.completarInstrucciones($11->exits, $12);
               codigo.completarInstrucciones($11->continues, $2);
               $$->exits = * new vector<int>;
               $$->continues = * new vector<int>;
            }
          | RFOREVER TDOSPUNTOS M bloque M 
            {
               $$ = new sentenciastruct;
               codigo.anadirInstruccion("goto " + $3);
               codigo.completarInstrucciones($4->exits, codigo.obtenRef());
               $$->exits = * new vector<int>;
               $$->continues = $4->continues;
            }
          | RBREAK RIF expresion TSEMIC
            {
               $$ = new sentenciastruct;
               codigo.completarInstrucciones($3->falses, codigo.obtenRef());
               $$->exits =  * new vector<int>($3->trues);
               $$->continues = * new vector<int>;
               delete $2;
            }
          | RCONTINUE TSEMIC M
            {
               $$ = new sentenciastruct;
               codigo.anadirInstruccion("goto");
               $$->exits =  *new vector<int>;
               $$->continues =  *new vector<int>($3);
            }
          | RREAD TPARENI variable TPAREND TSEMIC
            {
               $$ = new sentenciastruct;
					$$->exits = * new vector<int>;
               $$->continues = * new vector<int>;
					codigo.anadirInstruccion("read "+ *$3 + ";");
            }
          | RPRINT TPARENI expresion TPAREND TSEMIC
            {
               $$ = new sentenciastruct;
					$$->exits = * new vector<int>;
               $$->continues = * new vector<int>;
					codigo.anadirInstruccion("write "+ $3->str + ";");
					codigo.anadirInstruccion("writeln;");
            }
          ;

M : /* empty */
   { $$ = codigo.obtenRef(); }
   ;

variable : TIDENTIFIER
            {
               $$= $1;
            }
         ;

expresion : expresion TEQUAL expresion
            {
               $$->str= "";
               $$= new expresionstruct;
               $$->trues = * new vector<int>(codigo.obtenRef());
               $$->falses = * new vector<int>(codigo.obtenRef()+1);
               *$$ = makecomparison($1->str,*$2,$3->str); 

               delete $1; delete $3; 
            }
          | expresion TMAYOR expresion
            {
               $$->str= "";
               $$= new expresionstruct;
               $$->trues = * new vector<int>(codigo.obtenRef());
               $$->falses = * new vector<int>(codigo.obtenRef()+1);
               *$$ = makecomparison($1->str,*$2,$3->str); 

               delete $1; delete $3; 
            }
          | expresion TMENOR expresion
            {
               $$->str= "";
               $$= new expresionstruct;
               $$->trues = * new vector<int>(codigo.obtenRef());
               $$->falses = * new vector<int>(codigo.obtenRef()+1);
               *$$ = makecomparison($1->str,*$2,$3->str); 

               delete $1; delete $3; 
            }
          | expresion TMAYOREQ expresion
            {
               $$->str= "";
               $$= new expresionstruct;
               $$->trues = * new vector<int>(codigo.obtenRef());
               $$->falses = * new vector<int>(codigo.obtenRef()+1);
               *$$ = makecomparison($1->str,*$2,$3->str);  

               delete $1; delete $3; 
            }
          | expresion TMENOREQ expresion
            {
               $$->str= "";
               $$= new expresionstruct;
               $$->trues = * new vector<int>(codigo.obtenRef());
               $$->falses = * new vector<int>(codigo.obtenRef()+1);
               *$$ = makecomparison($1->str,*$2,$3->str); 

               delete $1; delete $3; 
            }
          | expresion TNOTEQUAL expresion
            {
               $$->str= "";
               $$= new expresionstruct;
               $$->trues = * new vector<int>(codigo.obtenRef());
               $$->falses = * new vector<int>(codigo.obtenRef()+1);
               *$$ = makecomparison($1->str,*$2,$3->str); 

               delete $1; delete $3; 
            }
          | expresion TPLUS expresion
            {
               $$= new expresionstruct;
               $$->trues = * new vector<int>;
               $$->falses = * new vector<int>;
               
               //$$->tipo = "operación aritmética";
               *$$ = makearithmetic($1->str,*$2,$3->str); 

               delete $1; delete $3; 
            }
          | expresion TMINUS expresion
            {
               $$= new expresionstruct;
               $$->trues = * new vector<int>;
               $$->falses = * new vector<int>;
               
               //$$->tipo = "operación aritmética";
               *$$ = makearithmetic($1->str,*$2,$3->str); 

               delete $1; delete $3; 
            }
          | expresion TMUL expresion
            {
               $$= new expresionstruct;
               $$->trues = * new vector<int>;
               $$->falses = * new vector<int>;
               
               *$$ = makearithmetic($1->str,*$2,$3->str); 

               delete $1; delete $3; 
            }
          | expresion TDIV expresion
            {
               $$= new expresionstruct;
               $$->trues = * new vector<int>;
               $$->falses = * new vector<int>;
               
               *$$ = makearithmetic($1->str,*$2,$3->str); 

               delete $1; delete $3; 
            }
          | TIDENTIFIER
            {
               $$= new expresionstruct;
               $$->trues = * new vector<int>;
               $$->falses = * new vector<int>;
               $$->str = *$1;
            }
          | TINTEGER
            {
               $$= new expresionstruct;
               $$->trues = * new vector<int>;
               $$->falses = * new vector<int>;
               $$->str = *$1;
               //$$->tipo= "Integer";
            }
          | TFLOAT
            {
               $$= new expresionstruct;
               $$->trues = * new vector<int>;
               $$->falses = * new vector<int>;
               $$->str = *$1;
               //$$->tipo= "Float";
            }
          | TPARENI expresion TPAREND
            {
               $$= new expresionstruct;
               $$->trues = $2->trues;
               $$->falses = $2->falses;
               $$->str = $2->str;
            }
          ;
%%

expresionstruct makecomparison(std::string &s1, std::string &s2, std::string &s3) {
  expresionstruct tmp ; 

  tmp.trues.push_back(codigo.obtenRef()) ;
  tmp.falses.push_back(codigo.obtenRef()+1) ;

  codigo.anadirInstruccion("if " + s1 + " " + s2 + " " + s3 + " goto") ;
  codigo.anadirInstruccion("goto") ;
  return tmp ;
}

expresionstruct makearithmetic(std::string &s1, std::string &s2, std::string &s3) {
  expresionstruct tmp ; 

  tmp.str = codigo.nuevoId() ;

  codigo.anadirInstruccion(tmp.str + " := " + s1 + " " +  s2 + " " +  s3 + ";") ;
  return tmp ;
}

vector<int> *unir(vector<int> lis1, vector<int> lis2){
        vector<int> *aux;
        aux = new vector<int>(lis1);

        aux->insert(aux->end(), lis2.begin(), lis2.end());

        return aux;
}

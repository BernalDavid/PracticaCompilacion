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



/* Funciones que se usan*/
expresionstruct makecomparison(std::string &s1, std::string &s2, std::string &s3) ;
expresionstruct makearithmetic(std::string &s1, std::string &s2, std::string &s3) ;
vector<int> *unir(vector<int> lis1, vector<int> lis2);

%}

/* 
   qué atributos tienen los tokens 
*/
%union {
    string *str ; 
    expresionstruct *expr;
    
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
%token <str> TLLAVEI TLLAVED TPARENI TPAREND TAND
%token <str> TEQUAL TMAYOR TMENOR TMAYOREQ TMENOREQ TNOTEQUAL
%token <str> TPLUS TMINUS TMUL TDIV


%type <str> programa
%type <str> bloque_ppl
%type <numlist> bloque
%type <str> decl_bl
%type <str> declaraciones
%type <lid> lista_de_ident
%type <lid> resto_lista_id
%type <str> tipo
%type <str> decl_de_subprogs
%type <str> decl_de_subprograma
%type <str> argumentos
%type <str> lista_de_param
%type <str> clase_par
%type <str> resto_lis_de_param
%type <numlist> lista_de_sentencias
%type <numlist> sentencia
%type <str> variable //o tipo <expr>???
%type <expr> expresion
%type <number> M
%type <numlist> N

//Prioridad y asociatividad de los operadores
%nonassoc TASSIG TNOTEQUAL TMENOR TMENOREQ TMAYOR TMAYOREQ
%left TPLUS TMINUS
%left TMUL TDIV

%start programa
%%

programa : RDEF RMAIN TPARENI TPAREND TDOSPUNTOS  
            {
            codigo.anadirInstruccion("def main ():" + $5);
            }
            bloque_ppl {
            codigo.anadirInstruccion("halt");
            codigo.esccribir();
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
         //Falta continue
         $$= new estructuraExpresion;
         $$->exits= $2->exits;
         $$= new estructuraExpresion:
         $$->continues = $2->continues;
         }
       ;

decl_bl : RLET declaraciones RIN
        | /* empty */
        ;

declaraciones :   declaraciones TSEMIC lista_de_ident TDOSPUNTOS tipo
                  {
                     codigo.anadirDeclaraciones($3->str, $5->tipo);
                  }
              |   lista_de_ident TDOSPUNTOS tipo
                  {
                     codigo.anadirDeclaraciones($1->str, $3->tipo);
                  }
              ;

lista_de_ident :  TIDENTIFIER resto_lista_id
                  {
                     $$ = $2; //añadir resto_lista_id
                     $$->push_back(*$1); //añadir al principio id
                     // codigo.completar() hay que hacerlo o basta con lo de arriba?
                  }
                  
               ;

resto_lista_id :  TCOMA TIDENTIFIER resto_lista_id
                  {
                     $$  = $3 ;
                     $$->push_back(*$2);
                     //codigo.completar ???
                  }
               |  /* empty */
                  {
                     $$ = new vector<string>;
                  }
               ;

tipo :   RINTEGER
         { 
         $$ = new std::string("Integer");
         }
      |  RFLOAT
         { 
         $$ = new std::string("Float");
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
                 { codigo.anadirParametros($1->lnom, $3->tipo, $4->clase); delete $1; delete $3; delete $4; }
                 resto_lis_de_param
               ;

clase_par : /* empty */
          | TAND { $$ = new std::string("and"); }
          ;

resto_lis_de_param : TSEMIC lista_de_ident TDOSPUNTOS clase_par tipo 
                     { codigo.anadirParametros($2->lnom, $4->tipo, $5->clase); delete $2; delete $4; delete $5; }
                     resto_lis_de_param
                     | /* empty */
                     ;

lista_de_sentencias : sentencia lista_de_sentencias {$$->exits = *unir($1->exits, $2->exits);} 
                    | /* empty */ { $$->exits = * new vector<int>;}
                    ;

sentencia : variable TASSIG expresion TSEMIC
            {
               $$= new sentenciastruct;
               codigo.anadirInstruccion(*$1 + " := " + $3->str + ";") ; 
               $$->exits: * new vector<int>;
               // o exits.clear() * new vector<int>??
               $$->tipo = "asignacion";
               delete $1 ; delete $3;
            }
          | RIF expresion TDOSPUNTOS M bloque M
            {
               $$ = new sentenciastruct;
	      	   codigo.completarInstrucciones($2->trues,$4);
    	  	      codigo.completarInstrucciones($2->falses,$6);
	      	   $$->exits = $5->exits;
               delete $2 ;
            }
          | RWHILE M expresion TDOSPUNTOS M bloque N RELSE TDOSPUNTOS M bloque
            {
               $$ = new sentenciastruct;
	      	   codigo.completarInstrucciones($3->trues,$5);
    	  	      codigo.completarInstrucciones($3->falses,$10+1);

               //REVISAR
               codigo.anadirInstruccion("goto");
               vector<int> tmp1; 
               tmp1.push_back($10);
               codigo.completarInstrucciones(tmp1, $2);

               codigo.completarInstrucciones($6->exits, $7+1);
               $$ = new vector<int>;
               //$$->exits.clear();
               /* No se si es necesario
                  $$->exits = $11->exits; */
               delete $4;
            }
          | RFOREVER TDOSPUNTOS M bloque M 
            {
               $$ = new sentenciastruct;
               codigo.anadirInstruccion("goto " + $3);
               codigo.completarInstrucciones($4, codigo.obtenRef());
               $$->exits= * new vector<int>;
            }
          | RBREAK RIF expresion TSEMIC
            {
               $$ = new sentenciastruct;
               codigo.completarInstrucciones($3->falses, codigo.obtenRef());
               $$->exits = $3->trues;
               delete $2;
            }
          | RCONTINUE TSEMIC
            /*{

            }*/
          | RREAD TPARENI variable TPAREND TSEMIC
            {
               $$ = new sentenciastruct;
					$$->exits = * new vector<int>;
					codigo.anadirInstruccion("read "+ *$3 + ";");
            }
          | RPRINT TPARENI expresion TPAREND TSEMIC
            {
               $$ = new sentenciastruct;
					$$->exits = * new vector<int>;
					codigo.anadirInstruccion("write "+ $3->str + ";");
					codigo.anadirInstruccion("writeln;");
            }
          ;

M : /* empty */
   { $$ = codigo.obtenRef(); }
   ;

N : /* empty */ 
   { 
      $$ = new vector<int>;
      codigo.anadirInstruccion("goto");
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
               *$$ = makecomparison($1->str,*$2,$3->str); 

               delete $1; delete $3; 
            }
          | expresion TMAYOR expresion
            {
               $$= new estructuraExpresion;
               $$->tipo = "comparación";
               *$$ = makecomparison($1->str,*$2,$3->str); 

               delete $1; delete $3; 
            }
          | expresion TMENOR expresion
            {
               $$= new estructuraExpresion;
               $$->tipo = "comparación";
               *$$ = makecomparison($1->str,*$2,$3->str); 

               delete $1; delete $3; 
            }
          | expresion TMAYOREQ expresion
            {
               $$= new estructuraExpresion;
               $$->tipo = "comparación";
               *$$ = makecomparison($1->str,*$2,$3->str); 

               delete $1; delete $3; 
            }
          | expresion TMENOREQ expresion
            {
               $$= new estructuraExpresion;
               $$->tipo = "comparación";
               *$$ = makecomparison($1->str,*$2,$3->str); 

               delete $1; delete $3; 
            }
          | expresion TNOTEQUAL expresion
            {
               $$= new estructuraExpresion;
               $$->tipo = "comparación";
               *$$ = makecomparison($1->str,*$2,$3->str); 

               delete $1; delete $3; 
            }
          | expresion TPLUS expresion
            {
               $$= new estructuraExpresion;
               $$->tipo = "operación aritmética";
               *$$ = makearithmetic($1->str,*$2,$3->str); 

               delete $1; delete $3; 
            }
          | expresion TMINUS expresion
            {
               $$= new estructuraExpresion;
               $$->tipo = "operación aritmética";
               *$$ = makearithmetic($1->str,*$2,$3->str); 

               delete $1; delete $3; 
            }
          | expresion TMUL expresion
            {
               $$= new estructuraExpresion;
               $$->tipo = "operación aritmética";
               *$$ = makearithmetic($1->str,*$2,$3->str); 

               delete $1; delete $3; 
            }
          | expresion TDIV expresion
            {
               $$= new estructuraExpresion;
               $$->tipo = "operación aritmética";
               *$$ = makearithmetic($1->str,*$2,$3->str); 

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
          | TFLOAT
            {
               $$= new estructuraExpresion;
               $$->n= *$1;
               $$->tipo= "Float";
            }
          | TPARENI expresion TPAREND
            {
               $$= $2;
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

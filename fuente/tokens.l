%option yylineno 
%option nounput

%{
 #include <string>
 #include <iostream>
 #include <vector>
 using namespace std ;
 #include "parser.hpp" 
 using namespace std;

 #define TOKEN(t) yylval.str = new string(yytext, yyleng) ; return t 

 extern "C" int yywrap() { return(1) ; }  

%}

%%
def                     TOKEN(RDEF) ;
main                    TOKEN(RMAIN);
let                     TOKEN(RLET);
in                      TOKEN(RIN);
if                      TOKEN(RIF);
else                    TOKEN(RELSE);
while                   TOKEN(RWHILE);
forever                 TOKEN(RFOREVER);
break                   TOKEN(RBREAK);
continue                TOKEN(RCONTINUE);
read                    TOKEN(RREAD);
println                 TOKEN(RPRINT);
integer                 TOKEN(RINTEGER);
float                   TOKEN(RFLOAT);


";"                     TOKEN(TSEMIC);
":"                     TOKEN(TDOSPUNTOS);
","                     TOKEN(TCOMA);

'''[^#]*[\n]*[^#]*'''   ;

#[^#]*[\n]+               ;

[ \t\n]                 ;

[a-zA-Z][a-zA-Z0-9]*([_]?[a-zA-Z0-9])*  TOKEN(TIDENTIFIER) ; 
[0-9]+[.][0-9]+([eE][+-]?[0-9]+)?       TOKEN(TFLOAT);
[0-9]+                                  TOKEN(TINTEGER);

"{"                     TOKEN(TLLAVEI);
"}"                     TOKEN(TLLAVED);
"("                     TOKEN(TPARENI);
")"                     TOKEN(TPAREND);
"&"                     TOKEN(TAND);

"="                     TOKEN(TASSIG);
"=""="                  TOKEN(TEQUAL);
">"                     TOKEN(TMAYOR);
"<"                     TOKEN(TMENOR);
">""="                  TOKEN(TMAYOREQ);
"<""="                  TOKEN(TMENOREQ);
"/""="                  TOKEN(TNOTEQUAL);

"+"                     TOKEN(TPLUS);
"-"                     TOKEN(TMINUS);
"*"                     TOKEN(TMUL);
"/"                     TOKEN(TDIV);

.                       { cout << "Token desconocido: " << yytext << endl; yyterminate();}
%%



/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>
#include <stdint.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */

 bool containNullCharStr;
 char stringConst[MAX_STR_CONST];
 int stringConstLen;

 

%}



/*
 * Define names for regular expressions here.
 */

%option noyywrap
%x LINE_COMMENT BLOCK_COMMENT STRING

DARROW          =>
ASSIGN          <-
LE          <=

DIGIT [0-9]
INTEGER [0-9]+
TYPE_ID [A-Z][a-zA-Z0-9_]*
OBJECT_ID [a-z][a-zA-Z0-9_]*
WHITESPACE [ \t\r\v\f]+



%%

{WHITESPACE}  { }

\n  { curr_lineno++; }


 /*
  *  Nested comments
  */

"--"      { BEGIN LINE_COMMENT; }
"(\*"     { BEGIN BLOCK_COMMENT; }
"\*)" {
  strcpy(cool_yylval.error_msg, "Unmatched *)");
  return (ERROR);
}

<LINE_COMMENT>\n {
   BEGIN 0;
   curr_lineno++;
}

<BLOCK_COMMENT>\n {
  curr_lineno++;
}

<BLOCK_COMMENT>"\*)" {
  BEGIN 0;
}

<BLOCK_COMMENT><<EOF>> {
  strcpy(cool_yylval.error_msg, "EOF in comment");
  BEGIN 0;
  return (ERROR);
}

<LINE_COMMENT>.  {}
<BLOCK_COMMENT>. {}




 /*
  *  The multiple-character operators.
  */

{DARROW}		  { return (DARROW); }
{ASSIGN}      { return (ASSIGN); }
{LE}          { return (LE); }



 /*
  *  The single-character operators.
  */

"{"  { return '{'; }
"}"	 { return '}'; }
"("	 { return '('; }
")"	 { return ')'; }
"~"	 { return '~'; }
","	 { return ','; }
";"	 { return ';'; }
":"	 { return ':'; }
"+"	 { return '+'; }
"-"	 { return '-'; }
"*"	 { return '*'; }
"/"	 { return '/'; }
"%"	 { return '%'; }
"."	 { return '.'; }
"<"	 { return '<'; }
"="	 { return '='; }
"@"	 { return '@'; }





 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */

  /* 
  * "(?i)" means starts case-insensitive mode
  */

(?i:CLASS)    { return (CLASS); }
(?i:IF)       { return (IF); }
(?i:ELSE)     { return (ELSE); }
(?i:FI)       { return (FI); }
(?i:IN)		  	{ return (IN); }
(?i:INHERITS)	{ return (INHERITS); }
(?i:LET)	  	{ return (LET); }
(?i:LOOP)		  { return (LOOP); }
(?i:POOL)		  { return (POOL); }
(?i:THEN)		  { return (THEN); }
(?i:WHILE)		{ return (WHILE); }
(?i:CASE)		  { return (CASE); }
(?i:ESAC)	   	{ return (ESAC); }
(?i:OF)			  { return (OF); }
(?i:NEW)		  { return (NEW); }
(?i:LE)			  { return (LE); }
(?i:NOT)		  { return (NOT); }
(?i:ISVOID)		{ return (ISVOID); }

t(?i:rue)		{
  cool_yylval.boolean = 1;
  return (BOOL_CONST);
}

f(?i:alse)		{
  cool_yylval.boolean = 0;
  return (BOOL_CONST);
}




 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */

  /* 
   * start string if '\"'  found  
   */

\" {
  memset(stringConst, 0,sizeof stringConst);
  stringConstLen = 0;
  containNullCharStr = false;
  BEGIN STRING;
}

 /* EOF found middle of a string */
<STRING><<EOF>> {
  strcpy(cool_yylval.error_msg, "EOF in string constant");
  BEGIN 0;
  return (ERROR);
}


<STRING>\\. {

  if(stringConstLen >= MAX_STR_CONST){
    strcpy(cool_yylval.error_msg, "String constant too long");
    BEGIN 0;
    return (ERROR);
  }

  switch(yytext[1]) {

    case '\"':
      stringConst[stringConstLen++] = '\"';
      break;
    case '\\':
      stringConst[stringConstLen++] = '\\';
      break;
    case 'b':
      stringConst[stringConstLen++] = '\b';
      break;
    case 'f':
      stringConst[stringConstLen++] = '\f';
      break;
    case 'n':
      stringConst[stringConstLen++] = '\n';
      break;
    case 't':
      stringConst[stringConstLen++] = '\t';
      break;
    case '0':
      stringConst[stringConstLen++] = 0;
      containNullCharStr = true;
      break;
    default:
      stringConst[stringConstLen++] = yytext[1];
    
  }

}

 /* found '\\' at the end of a line */
<STRING>\\\n {
  curr_lineno++;
}

 /*found newline charactor middle of a string*/

<STRING>\n {
  curr_lineno++;
  strcpy(cool_yylval.error_msg, "Unterminated string constant");
  BEGIN 0;
  return ERROR;
}

<STRING>\" {

  if(stringConstLen > 1 && containNullCharStr){
    strcpy(cool_yylval.error_msg, "String contains null character");
    BEGIN 0;
    return (ERROR);
  }

  cool_yylval.symbol = stringtable.add_string(stringConst);
  BEGIN 0;
  return (STR_CONST);

}

<STRING>. {

  if(stringConstLen >= MAX_STR_CONST) {
    strcpy(cool_yylval.error_msg, "String constant too long");
    BEGIN 0;
    return (ERROR);
  }

  stringConst[stringConstLen++] = yytext[0];

}


 /*
  *  Integers and identifiers.
  */

{INTEGER} {
  cool_yylval.symbol = inttable.add_string(yytext);
  return (INT_CONST);
}

{TYPE_ID} {
  cool_yylval.symbol = idtable.add_string(yytext);
  return (TYPEID);
}

{OBJECT_ID} {
  cool_yylval.symbol = idtable.add_string(yytext);
  return (OBJECTID);
}



.	{
  strcpy(cool_yylval.error_msg, yytext);
  return (ERROR);
}
 


%%

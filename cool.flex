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
#include <string.h>

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
int comment_depth;
int string_len;

bool isStrTooLong();
void appendChar(char c);
int strTooLong();
void clearStr();

%}

/*
 * Define names for regular expressions here.
 */

DARROW          =>
ASSIGN          <-
LE              <=
ALPHANUM        [a-zA-Z0-9_]

%x COMMENT STRING BROKENSTRING

%%

 /*
  *  Nested comments
  */

"(*"                    { comment_depth = 0; BEGIN(COMMENT); }
<COMMENT>"(*"           { comment_depth++; }
<COMMENT>"*)"           { comment_depth--; if (!comment_depth) BEGIN(0); }
<COMMENT>\n             { curr_lineno++; }
<COMMENT>.              ;

<INITIAL>"*)"           { 
	cool_yylval.error_msg = "Unmatched *)";
	return (ERROR);
}

<COMMENT><<EOF>>        {
        BEGIN(0);
        cool_yylval.error_msg = "EOF in comment";
        return (ERROR);
}

"--".*\n?               { curr_lineno++; }

 /*
  *  The multiple-character operators.
  */
{DARROW}		{ return (DARROW); }
{ASSIGN}                { return (ASSIGN); }
{LE}                    { return (LE); }

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */
(?i:class)              { return (CLASS); }
(?i:else)               { return (ELSE); }
(?i:fi)                 { return (FI); }
(?i:if)                 { return (IF); }
(?i:in)                 { return (IN); }
(?i:inherits)           { return (INHERITS); }
(?i:let)                { return (LET); }
(?i:loop)               { return (LOOP); }
(?i:pool)               { return (POOL); }
(?i:then)               { return (THEN); }
(?i:while)              { return (WHILE); }
(?i:case)               { return (CASE); }
(?i:esac)               { return (ESAC); }
(?i:of)                 { return (OF); }
(?i:new)                { return (NEW); }
(?i:isvoid)             { return (ISVOID); }
(?i:not)                { return (NOT); }

t(?i:rue)               { cool_yylval.boolean = true; return BOOL_CONST; }
f(?i:alse)              { cool_yylval.boolean = false; return BOOL_CONST; }

[0-9]+                   { 
	cool_yylval.symbol = inttable.add_string(yytext);
	return (INT_CONST);
}

[A-Z]{ALPHANUM}*         {
        cool_yylval.symbol = idtable.add_string(yytext);
        return (TYPEID);
}

[a-z]{ALPHANUM}*         {
        cool_yylval.symbol = idtable.add_string(yytext);
        return (OBJECTID);
}
 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */
[+\-*/~@\.\(\){}<=,:;]              { return yytext[0]; }

<BROKENSTRING>.*[\"\n]  { BEGIN(0); }

\"                      { BEGIN(STRING); }
<STRING>\"              {
	cool_yylval.symbol = stringtable.add_string(string_buf, string_len);
	clearStr();
	BEGIN(0);
	return (STR_CONST);
}

<STRING>\n              {
	curr_lineno++;
	BEGIN(0);
	clearStr();
	cool_yylval.error_msg = "Unterminated string constant";
	return (ERROR);
}

<STRING>\\\n            {
	/* escaped slash then newline */
	curr_lineno++;
	if (isStrTooLong()) { return strTooLong(); }
	appendChar('\n');
}

<STRING>\0|\\\0         {
	cool_yylval.error_msg = "String contains null character";
	BEGIN(BROKENSTRING);
	return (ERROR);
}

<STRING>\\([^\n\"\0]) {
	if (isStrTooLong()) { return strTooLong(); }
	switch (yytext[1]) {
		case 'n':
		appendChar('\n');
		break;
		
		case 't':
		appendChar('\t');
		break;

		case 'b':
		appendChar('\b');
		break;

		case 'f':
		appendChar('\f');
		break;

		default:
		appendChar(yytext[1]);
		break;
	}
}

<STRING><<EOF>>       {
	cool_yylval.error_msg = "EOF in string constant";
	BEGIN(0);
	return (ERROR);
}

<STRING>.             {
	if (isStrTooLong()) { return strTooLong(); }
	appendChar(yytext[0]);
}

\n                    { curr_lineno++; }
[ \f\r\t\v]           ;
.                     { cool_yylval.error_msg = yytext; return (ERROR); }
       
%%
void appendChar(char c) {
    	*string_buf_ptr++ = c;
	string_len++;
}

bool isStrTooLong() {
	return string_len >= MAX_STR_CONST - 1;
}

void clearStr() {
	memset(string_buf, '\0', sizeof(string_buf));
	string_buf_ptr = string_buf;
	string_len = 0;
}

int strTooLong() {
	clearStr();
	cool_yylval.error_msg = "String constant too long";
	return (ERROR);
}

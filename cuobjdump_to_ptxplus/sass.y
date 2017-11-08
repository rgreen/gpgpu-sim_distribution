// Copyright (c) 2009-2012, Jimmy Kwa, Andrew Boktor
// The University of British Columbia
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
// Redistributions in binary form must reproduce the above copyright notice, this
// list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
// Neither the name of The University of British Columbia nor the names of its
// contributors may be used to endorse or promote products derived from this
// software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

%{
#include <stdio.h>
#include "cuobjdumpInstList.h"

int yylex(void);
void yyerror(const char*);
void debug_print( const char *s );

extern cuobjdumpInstList *g_instList;

cuobjdumpInst *instEntry;
int delay_set = 0;
int hex_set = 0;
int neg_set = 0;
%}


%union {
  double double_value;
  float  float_value;
  int    int_value;
  char * string_value;
  void * ptr_value;
}

%token <string_value> BAR DEPBAR
%token <string_value> ADA AND ANDS BRA BRX JCAL CAL COS DADD DMIN DMAX DFMA FFMA DMUL EX2 F2F F2I FADD
%token <string_value> FADD32 FADD32I FCMP FMAD FMAD32I FMUL FMUL32 FMUL32I FSET FSETP DSET G2R
%token <string_value> GLD GST LDC I2F I2I IADD IADD3 IADD32 IADD32I IMAD ISCADD ISAD IMAD24 IMAD32I IMAD32 IADDCARRY XMAD
%token <string_value> IMUL IMUL24 IMUL24H IMULS24 IMUL32 IMUL32S24 IMUL32U24 IMUL32I IMUL32I24 IMUL32IS24
%token <string_value> ISET ISETP LEA LG2 LLD LST MOV MOV32 MVC MVI NOP NOT NOTS OR ORS
%token <string_value> R2A R2G R2GU16U8 RCP RCP32 RET PRET RRO RSQ SIN SHL SHR SSY XOR XORS 
%token <string_value> S2R SASS_LD STS SEL LDS SASS_ST IMIN IMAX IMNMX A2R FMAX FMIN TEX TEX32 C2R EXIT VABSDIFF
%token <string_value> GRED PBK BRK R2C GATOM VOTE BFE SHF
%token <string_value> EQ EQU GE GEU GT GTU LE LEU LT LTU NE NEU
%token <string_value> DOTBEXT DOTS DOTSFU
%token <string_value> DOTTRUNC DOTCEIL DOTFLOOR DOTIR DOTUN DOTNODEP DOTSAT DOTANY DOTALL DOTL 
%token <string_value> DOTF16 DOTF32 DOTF64 DOTS8 DOTS16 DOTS32 DOTS64 DOTS128 DOTU8 DOTU16 DOTU32 DOTU24 EXTEND EXTEND8 EXTEND64 DOT64 DOT128 DOTU64 DOTV128
%token <string_value> DOTHI DOTNOINC
%token <string_value> DOTEQ DOTEQU DOTFTZ DOTFALSE DOTGE DOTGEU DOTGT DOTGTU DOTLE DOTLEU DOTLT DOTLTU DOTNE DOTNEU DOTNSF DOTSF DOTCARRY
%token <string_value> CC DOTCC DOTX DOTRED DOTPOPC DOTAND DOTCHI DOTCLO DOTRS DOTMRG DOTPSL DOTCBCC
%token <string_value> REGISTER REGISTERLO REGISTERHI OFFSETREGISTER
%token <string_value> PREDREGISTER PREDREGISTER2 PREDREGISTER3 SREGISTER NEWPREDREGISTER PSETP
%token <string_value> VERSIONHEADER FUNCTIONHEADER
%token <string_value> SMEMLOCATION ABSSMEMLOCATION GMEMLOCATION CMEMLOCATION LMEMLOCATION
%token <string_value> IDENTIFIER
%token <string_value> HEXLITERAL FLOAT NEGFLOAT
%token <string_value> LEFTBRACKET RIGHTBRACKET AT QUOTE FLAGHEADER
%token <string_value> PIPE TILDE EXCLAM
%token <string_value> NEWLINE SEMICOLON /*COMMA*/
%token <string_value> LABEL LABELSTART LABELEND
%token <string_value> PTXHEADER ELFHEADER
%token <string_value> INFOARCHVERSION
%token <string_value> INFOCODEVERSION_HEADER INFOCODEVERSION
%token <string_value> INFOPRODUCER
%token <string_value> INFOHOST
%token <string_value> INFOCOMPILESIZE_HEADER INFOCOMPILESIZE
%token <string_value> INFOIDENTIFIER DOT
%token <string_value> INSTHEX
%token <string_value> OSQBRACKET CSQBRACKET

	/* set types for rules */
%type<string_value> simpleInstructions
%type<string_value> predicateModifier
%type<string_value> opTypes

%%

	/*translation rules*/
program		: program sassCode
			| sassCode;

sassCode	: VERSIONHEADER IDENTIFIER NEWLINE functionList			{ debug_print($1); debug_print($2); debug_print(" No parsing errors\n\n");  }
		| NEWLINE VERSIONHEADER IDENTIFIER NEWLINE functionList	{ debug_print($2); debug_print($3); debug_print(" No parsing errors\n\n");  }
		| VERSIONHEADER IDENTIFIER NEWLINE;

functionList	: functionList function
				| function
				;
				
function	: FUNCTIONHEADER IDENTIFIER NEWLINE headerflags {
					debug_print($1); 
					debug_print($2);
					debug_print("\n");
					g_instList->addEntry($2);
					instEntry = new cuobjdumpInst();
					instEntry->setBase(".entry");
					g_instList->add(instEntry);
					g_instList->getListEnd().addOperand($2);} statementList NEWLINE
					;

headerflags	:	FLAGHEADER AT QUOTE flagsname QUOTE {
					debug_print($1);
					debug_print("\n");}
		|	{}
					;

flagsname	:	IDENTIFIER IDENTIFIER LEFTBRACKET IDENTIFIER RIGHTBRACKET;

statementList	: statementList statement NEWLINE	{ debug_print("\n"); }
		| statementList statement SEMICOLON NEWLINE	{ debug_print(";\n"); }
		| statement NEWLINE			{ debug_print("\n"); }
		| statement SEMICOLON NEWLINE			{ debug_print(";\n"); }
		| NEWLINE	{}
		;

statement	: { instEntry = new cuobjdumpInst(); } instructionLabel statementend
	        | instructionHex	{
						// delay setting label to next inst
						delay_set = 1;
					}
			;

statementend	: instructionHex assemblyInstruction
	        | assemblyInstruction instructionHex
		| /*blank*/ {instEntry->setBase("NOP"); g_instList->add(instEntry); debug_print("NOP");}
		;

instructionHex	: INSTHEX {if (hex_set == 1) {
					hex_set = 0;
					char* tempInput = $1;
					char* hex = new char[11];
					hex[10] = '\0';
					hex[9] = '0';
					hex[8] = '0';
					hex[7] = '0';
					hex[6] = tempInput[15];
					hex[5] = tempInput[14];
					hex[4] = tempInput[13];
					hex[3] = tempInput[12];
					if (tempInput[11]>='a') {
						hex[2] = tempInput[11]-'a'+2+'0';
					} else if (tempInput[11]>='8'){
						hex[2] = tempInput[11]-'8'+'0';
					} else {
						hex[2] = tempInput[11];
					}
					hex[2] = neg_set == 1?(hex[2]-'0'+'a'-2):hex[2];
					hex[1] = 'x';
					hex[0] = '0';
					debug_print(hex);
					g_instList->getListEnd().changeOperand(hex);
				}
				neg_set = 0;
		};

instructionLabel	: LABELSTART LABEL LABELEND	{ char* tempInput = $2;
							  if (delay_set) {
							        instEntry->setBase("NOP");
							        delay_set = 0;
							        char* nopInput=new char[4];
								strcpy(nopInput, tempInput);
							        char* nopLabel = new char[12];
							        unsigned long addr = strtol(nopInput, NULL, 16);
							        nopLabel[0] = 'l';
							        nopLabel[1] = '0';
							        nopLabel[2] = 'x';
							        /*TODO: assume all inst is 8 byte*/
							        addr-=8;
							        sprintf(nopInput, "%lx", addr);
							        for(int i=0; i<(8-strlen(nopInput)); i++)
							        {
									nopLabel[3+i] = '0';
							        }
							        for(int i=(11-strlen(nopInput)); i<11; i++)
							        {
									nopLabel[i] = nopInput[i-(11-strlen(nopInput))];
							        }
							        nopLabel[11] = '\0';
							        debug_print("Control Code\n");
							        instEntry->setLabel(nopLabel);
							        g_instList->add(instEntry);
							        instEntry = new cuobjdumpInst();
							  }
							  char* tempLabel = new char[12];
							  tempLabel[0] = 'l';
							  tempLabel[1] = '0';
							  tempLabel[2] = 'x';
							  for(int i=0; i<(8-strlen(tempInput)); i++)
							  {
								tempLabel[3+i] = '0';
							  }
							  for(int i=(11-strlen(tempInput)); i<11; i++)
							  {
								tempLabel[i] = tempInput[i-(11-strlen(tempInput))];
							  }
							  tempLabel[11] = '\0';
							  instEntry->setLabel(tempLabel); }
			;

assemblyInstruction	: baseInstruction modifierList operandList	{ }
			| baseInstruction modifierList operandList SEMICOLON	{ }
			| predIdentifier baseInstruction modifierList operandList SEMICOLON	{ }
					/*| baseInstruction operandList			{ }*/
					/*| baseInstruction modifierList			{ }*/
					/*| baseInstruction				{ }*/
					;

predIdentifier	: AT NEWPREDREGISTER { debug_print($2); debug_print(" "); instEntry->setPredicate($2); instEntry->addPredicateModifier(".EQU");}
		| AT EXCLAM NEWPREDREGISTER { debug_print("!"); debug_print($3); debug_print(" "); instEntry->setPredicate($3); instEntry->addPredicateModifier(".NE");}

baseInstruction : simpleInstructions	{ debug_print($1); instEntry->setBase($1); g_instList->add(instEntry);}
		| branchInstructions
		| GRED DOT simpleInstructions	{ debug_print($1); instEntry->setBase($1); g_instList->add(instEntry); g_instList->getListEnd().addBaseModifier($3);}
		| GATOM DOT simpleInstructions	{ debug_print($1); instEntry->setBase($1); g_instList->add(instEntry); g_instList->getListEnd().addBaseModifier($3);}
		| pbkInstruction
		;

simpleInstructions	: ADA | AND | ANDS | BRX | COS | DADD | DMIN | DMAX | DFMA | FFMA | DMUL | EX2 | F2F
					| F2I | FADD | FADD32 | FADD32I | FCMP | FMAD | FMAD32I | FMUL
					| FMUL32 | FMUL32I | FSET | FSETP | DSET | G2R | GLD | GST | LDC | I2F | I2I
					| IADD | IADD32 | IADD32I | IADD3 | IMAD | ISCADD | ISAD | IMAD24 | IMAD32I | IMAD32 | IMUL | XMAD
					| IMUL24 | IMUL24H | IMULS24 | IMUL32 | IMUL32S24 | IMUL32I | IMUL32I24 | IMUL32IS24
					| IMUL32U24
					| ISET | ISETP | LEA| LG2 | LLD | LST | MOV | MOV32 | MVC | MVI | NOP
					| NOT | NOTS | OR | ORS | R2A | R2G | R2GU16U8 | RCP | RCP32 | RET | PRET | RRO 
					| RSQ | SHL | SHR | SIN | SSY | XOR | XORS | S2R | SASS_LD | STS | SEL
					| LDS | SASS_ST | EXIT | BAR | DEPBAR | IMIN | IMAX | IMNMX |  A2R | FMAX | FMIN 
					| TEX | TEX32 | C2R | BRK | R2C | IADDCARRY | VOTE | BFE | SHF | PSETP | VABSDIFF
					;

pbkInstruction	:	PBK {
						debug_print($1); instEntry->setBase($1); g_instList->add(instEntry);
					} HEXLITERAL {
						char* tempInput = $3;
						char* tempLabel = new char[12];
						tempLabel[0] = 'l';
						tempLabel[1] = '0';
						tempLabel[2] = 'x';
						for(int i=0; i<(10-strlen(tempInput)); i++)
						{
							tempLabel[3+i] = '0';
						}
						for(int i=(13-strlen(tempInput)); i<11; i++)
						{
							tempLabel[i] = tempInput[i-(11-strlen(tempInput))];
						}
						tempLabel[11] = '\0';
						g_instList->getListEnd().addOperand(tempLabel);
						g_instList->addCubojdumpLabel(tempLabel);
					}
				;

branchInstructions	: BRA {debug_print($1); instEntry->setBase($1); g_instList->add(instEntry);} instructionPredicate HEXLITERAL
				{ debug_print($4);
				  char* tempInput = $4;
				  char* tempLabel = new char[12];
				  tempLabel[0] = 'l';
				  tempLabel[1] = '0';
				  tempLabel[2] = 'x';
				  for(int i=0; i<(10-strlen(tempInput)); i++)
				  {
					tempLabel[3+i] = '0';
				  }
				  for(int i=(13-strlen(tempInput)); i<11; i++)
				  {
					tempLabel[i] = tempInput[i-(11-strlen(tempInput))];
				  }
				  tempLabel[11] = '\0';
				  g_instList->getListEnd().addOperand(tempLabel);
				  g_instList->addCubojdumpLabel(tempLabel);}
			| BRA {debug_print($1); instEntry->setBase($1); g_instList->add(instEntry);} HEXLITERAL
				{ debug_print($3);
				  char* tempInput = $3;
				  char* tempLabel = new char[12];
				  tempLabel[0] = 'l';
				  tempLabel[1] = '0';
				  tempLabel[2] = 'x';
				  for(int i=0; i<(10-strlen(tempInput)); i++)
				  {
					tempLabel[3+i] = '0';
				  }
				  for(int i=(13-strlen(tempInput)); i<11; i++)
				  {
					tempLabel[i] = tempInput[i-(11-strlen(tempInput))];
				  }
				  tempLabel[11] = '\0';
				  g_instList->getListEnd().addOperand(tempLabel);
				  g_instList->addCubojdumpLabel(tempLabel);}
			| BRA CC DOTNEU {debug_print($1); instEntry->setBase($1); g_instList->add(instEntry);} HEXLITERAL
				{ debug_print($3);
				  char* tempInput = $3;
				  char* tempLabel = new char[12];
				  tempLabel[0] = 'l';
				  tempLabel[1] = '0';
				  tempLabel[2] = 'x';
				  for(int i=0; i<(10-strlen(tempInput)); i++)
				  {
					tempLabel[3+i] = '0';
				  }
				  for(int i=(13-strlen(tempInput)); i<11; i++)
				  {
					tempLabel[i] = tempInput[i-(11-strlen(tempInput))];
				  }
				  tempLabel[11] = '\0';
				  g_instList->getListEnd().addOperand(tempLabel);
				  g_instList->addCubojdumpLabel(tempLabel);}
			| CAL {debug_print($1); instEntry->setBase($1); g_instList->add(instEntry);} HEXLITERAL
				{ debug_print($3);
				  char* tempInput = $3;
				  char* tempLabel = new char[12];
				  tempLabel[0] = 'l';
				  tempLabel[1] = '0';
				  tempLabel[2] = 'x';
				  for(int i=0; i<(10-strlen(tempInput)); i++)
				  {
					tempLabel[3+i] = '0';
				  }
				  for(int i=(13-strlen(tempInput)); i<11; i++)
				  {
					tempLabel[i] = tempInput[i-(11-strlen(tempInput))];
				  }
				  tempLabel[11] = '\0';
				  g_instList->getListEnd().addOperand(tempLabel);
				  g_instList->addCubojdumpLabel(tempLabel);}
			
			| CAL {debug_print($1); instEntry->setBase($1); g_instList->add(instEntry);} DOTNOINC HEXLITERAL
				{ debug_print($4);
				  char* tempInput = $4;
				  char* tempLabel = new char[12];
				  tempLabel[0] = 'l';
				  tempLabel[1] = '0';
				  tempLabel[2] = 'x';
				  for(int i=0; i<(10-strlen(tempInput)); i++)
				  {
					tempLabel[3+i] = '0';
				  }
				  for(int i=(13-strlen(tempInput)); i<11; i++)
				  {
					tempLabel[i] = tempInput[i-(11-strlen(tempInput))];
				  }
				  tempLabel[11] = '\0';
				  g_instList->getListEnd().addOperand(tempLabel);
				  g_instList->addCubojdumpLabel(tempLabel);}
			| JCAL {debug_print($1); instEntry->setBase($1); g_instList->add(instEntry);} HEXLITERAL

			;

modifierList	: modifier modifierList
				/*| modifier */
				|
				;

modifier	: opTypes	{ debug_print($1); g_instList->getListEnd().addTypeModifier($1);}
		| DOTBEXT		{ g_instList->getListEnd().addBaseModifier(".bext"); }
		| DOTS			{ g_instList->getListEnd().addBaseModifier(".s"); }
		| DOTSFU		{ g_instList->getListEnd().addBaseModifier(".sfu"); }
		| DOTTRUNC		{ g_instList->getListEnd().addBaseModifier(".rz"); }
		| DOTCEIL		{ g_instList->getListEnd().addBaseModifier(".rp"); }
		| DOTFLOOR		{ g_instList->getListEnd().addBaseModifier(".rm"); }
		| DOTFTZ		{ g_instList->getListEnd().addBaseModifier(".ftz"); }
		| DOTX			{ g_instList->getListEnd().addBaseModifier(".x"); }
		| DOTRED		{ g_instList->getListEnd().addBaseModifier(".red"); }
		| DOTPOPC		{ g_instList->getListEnd().addBaseModifier(".popc"); }
		| DOTIR			{ g_instList->getListEnd().addBaseModifier(".ir"); }
		| DOTUN			{ /*g_instList->getListEnd().addBaseModifier(".un"); */}
		| DOTNODEP		{ /*g_instList->getListEnd().addBaseModifier(".nodep"); */}
		| DOTANY		{ g_instList->getListEnd().addBaseModifier(".any"); }
		| DOTALL		{ g_instList->getListEnd().addBaseModifier(".all"); }
		| DOTGE			{ g_instList->getListEnd().addBaseModifier(".ge"); }
		| DOTLE			{ g_instList->getListEnd().addBaseModifier(".le"); }
		| DOTLEU		{ g_instList->getListEnd().addBaseModifier(".leu"); }
		| DOTGT			{ g_instList->getListEnd().addBaseModifier(".gt"); }
		| DOTLT			{ g_instList->getListEnd().addBaseModifier(".lt"); }
		| DOTEQ			{ g_instList->getListEnd().addBaseModifier(".eq"); }
		| DOTNE			{ g_instList->getListEnd().addBaseModifier(".ne"); }
		| DOTRS			{ g_instList->getListEnd().addBaseModifier(".rs"); }
		| DOTCHI		{ g_instList->getListEnd().addBaseModifier(".chi"); }
		| DOTCLO		{ g_instList->getListEnd().addBaseModifier(".clo"); }
		| DOTMRG		{ g_instList->getListEnd().addBaseModifier(".mrg"); }
		| DOTPSL		{ g_instList->getListEnd().addBaseModifier(".psl"); }
		| DOTCBCC		{ g_instList->getListEnd().addBaseModifier(".cbcc"); }
		| DOTL			{ g_instList->getListEnd().addBaseModifier(".l"); }
		
		;

opTypes		: DOTF16	//{ debug_print($1); g_instList->getListEnd().addTypeModifier($1);}
		| DOTF32	//{ debug_print($1); g_instList->getListEnd().addTypeModifier($1);}
		| DOTF64	//{ debug_print($1); g_instList->getListEnd().addTypeModifier($1);}
		| DOTS8		//{ debug_print($1); g_instList->getListEnd().addTypeModifier($1);}
		| DOTS16	//{ debug_print($1); g_instList->getListEnd().addTypeModifier($1);}
		| DOTS32	//{ debug_print($1); g_instList->getListEnd().addTypeModifier($1);}
		| DOTS64	//{ debug_print($1); g_instList->getListEnd().addTypeModifier($1);}
		| DOTS128	//{ debug_print($1); g_instList->getListEnd().addTypeModifier($1);}
		| DOTU8		//{ debug_print($1); g_instList->getListEnd().addTypeModifier($1);}
		| DOTU16	//{ debug_print($1); g_instList->getListEnd().addTypeModifier($1);}
		| DOTU32	//{ debug_print($1); g_instList->getListEnd().addTypeModifier($1);}
		| DOTU24	//{ debug_print($1); g_instList->getListEnd().addTypeModifier($1);}
		| EXTEND	//{ debug_print($1); g_instList->getListEnd().addTypeModifier($1);}
		| EXTEND64	//{ debug_print($1); g_instList->getListEnd().addTypeModifier($1);}
		| EXTEND8	//{ debug_print($1); g_instList->getListEnd().addTypeModifier($1);}
		| DOT64		//{ debug_print($1); g_instList->getListEnd().addTypeModifier($1);}
		| DOT128	//{ debug_print($1); g_instList->getListEnd().addTypeModifier($1);}
		| DOTU64	//{ debug_print($1); g_instList->getListEnd().addTypeModifier($1);}
		| DOTV128	//{ debug_print($1); g_instList->getListEnd().addTypeModifier($1);}
		| DOTHI		//{ debug_print($1); g_instList->getListEnd().addTypeModifier($1);}
		;

operandList	: operandList { debug_print(" "); } /*COMMA*/ operand	{}
			/*| { debug_print(" "); } operand		{}*/
			|
			;

operand		: registerlocation
		| PIPE registerlocation PIPE	{ g_instList->getListEnd().addBaseModifier(".abs"); }
		| TILDE registerlocation
		| LEFTBRACKET instructionPredicate RIGHTBRACKET
		| memorylocation opTypes { debug_print($2); g_instList->getListEnd().addTypeModifier($2);}
		| memorylocation
		| immediateValue
		| extraModifier
		| operandPredicate
		| preOperand
		;
/* regMod will be also ignored */
registerlocation	: REGISTER regMod	{ debug_print($1); g_instList->addCuobjdumpRegister($1);}
			| EXCLAM NEWPREDREGISTER {debug_print("!");
				debug_print($2);
				char* tempInput= $2;
				char* reg = new char[7];
				reg[0]=tempInput[0];
				reg[1]=tempInput[1];
				reg[2]='.';
				reg[3]='N';
				reg[4]='E';
				reg[5]='G';
				reg[6]='\0';
				debug_print(reg);
				g_instList->addCuobjdumpPredReg(reg);
			}
			| REGISTERLO	{ debug_print($1); g_instList->addCuobjdumpRegister($1,true);}
			| REGISTERHI	{ debug_print($1); g_instList->addCuobjdumpRegister($1,true);}
			| SREGISTER		{ debug_print($1); g_instList->addCuobjdumpRegister($1,false);}
			| OFFSETREGISTER	{ debug_print($1); g_instList->addCuobjdumpRegister($1);}
			| PREDREGISTER PREDREGISTER2	{ debug_print($1); debug_print(" "); debug_print($2); g_instList->addCuobjdumpDoublePredReg($1, $2);}
			| PREDREGISTER REGISTER	{ debug_print($1); debug_print(" "); debug_print($2); g_instList->addCuobjdumpDoublePredReg($1, $2);}
			| NEWPREDREGISTER	{ debug_print($1); g_instList->addCuobjdumpPredReg($1);}
			/*| REGISTER PREDREGISTER3 { debug_print($1); debug_print(" "); debug_print($2); g_instList->addCuobjdumpRegister($1); debug_print("WEIRD CASE\n");}*/
			;

regMod		: DOTCC
			|
			;


memorylocation	: SMEMLOCATION	{ debug_print($1); g_instList->addCuobjdumpMemoryOperand($1,1);}
		|	ABSSMEMLOCATION {
				debug_print($1);
				char* input = $1;
				char* temp = new char[99];
				temp[0] = input[1];
				unsigned i=1;
				while (i < strlen(input)-2) {
					temp[i] = input[i+2];
					i++;
				}
				g_instList->addCuobjdumpMemoryOperand(temp,1);
				g_instList->getListEnd().addBaseModifier(".abs");
			}
/* Register of the format [R0] will be recognize as global access R0 */
		| GMEMLOCATION	{ debug_print($1); g_instList->addCuobjdumpMemoryOperand($1,2);}
		| CMEMLOCATION	{ debug_print($1); g_instList->addCuobjdumpMemoryOperand($1,0);}
		| LMEMLOCATION	{ debug_print($1); g_instList->addCuobjdumpMemoryOperand($1,3);}
		;

immediateValue	: IDENTIFIER { debug_print($1); g_instList->getListEnd().addOperand($1);}
		| HEXLITERAL { debug_print($1); g_instList->getListEnd().addOperand($1);}
		| FLOAT { debug_print($1); g_instList->getListEnd().addOperand("NUM"); hex_set = 1;}
		| NEGFLOAT { debug_print($1); g_instList->getListEnd().addOperand("NEGNUM"); hex_set = 1; neg_set = 1;}
		;

extraModifier	: EQ	{ debug_print($1); g_instList->getListEnd().addBaseModifier($1);} 
		| EQU	{ debug_print($1); g_instList->getListEnd().addBaseModifier($1);}
		| GE	{ debug_print($1); g_instList->getListEnd().addBaseModifier($1);}
		| GEU	{ debug_print($1); g_instList->getListEnd().addBaseModifier($1);}
		| GT	{ debug_print($1); g_instList->getListEnd().addBaseModifier($1);}
		| GTU	{ debug_print($1); g_instList->getListEnd().addBaseModifier($1);}
		| LE	{ debug_print($1); g_instList->getListEnd().addBaseModifier($1);}
		| LEU	{ debug_print($1); g_instList->getListEnd().addBaseModifier($1);}
		| LT	{ debug_print($1); g_instList->getListEnd().addBaseModifier($1);}
		| LTU	{ debug_print($1); g_instList->getListEnd().addBaseModifier($1);}
		| NE	{ debug_print($1); g_instList->getListEnd().addBaseModifier($1);}
		| NEU	{ debug_print($1); g_instList->getListEnd().addBaseModifier($1);}
		;

instructionPredicate	: PREDREGISTER3	predicateModifier {debug_print($1); debug_print($2);
								g_instList->getListEnd().setPredicate($1);
								g_instList->getListEnd().addPredicateModifier($2);}
						| PREDREGISTER3 {debug_print($1); g_instList->getListEnd().setPredicate($1);}
			;

operandPredicate	:	PREDREGISTER3	predicateModifier {
							debug_print($1); 
							debug_print($2);
							//g_instList->getListEnd().addOperand($1);
							g_instList->getListEnd().setPredicate($1);
							g_instList->getListEnd().addPredicateModifier($2);
							/*May be the modifier needs to be added too*/
						}
					|	PREDREGISTER3 {
							debug_print("HELLO: "); 
							debug_print($1); 
							g_instList->getListEnd().addOperand($1);
						}
					;


preOperand	: EX2	{ debug_print($1); g_instList->getListEnd().addBaseModifier("ex2");}
		| SIN	{ debug_print($1); g_instList->getListEnd().addBaseModifier("sin");}
		| COS	{ debug_print($1); g_instList->getListEnd().addBaseModifier("cos");}
		;

predicateModifier	: DOTEQ	{ }
			| DOTEQU	{ }
			| DOTFALSE	{ }
			| DOTGE	{ }
			| DOTGEU	{ }
			| DOTGT	{ }
			| DOTGTU	{ }
			| DOTLE	{ }
			| DOTLEU	{ }
			| DOTLT	{ }
			| DOTLTU	{ }
			| DOTNE	{ }
			| DOTNEU	{ }
			| DOTNSF	{ }
			| DOTSF	{ }
			| DOTCARRY	{ }
			;

%%

/*support c++ functions go here*/

void debug_print( const char *s )
{
	// uncomment to debug
	// printf("%s",s);
}

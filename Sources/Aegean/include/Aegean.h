//
//  Aegean.h
//  Oovium
//
//  Created by Joe Charlier on 2/4/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

#include "Morph.h"

typedef unsigned char byte;
typedef unsigned short mnimi;

// Dim =====
typedef union {
	long n;
	double x;
	void* p;
} Dim;

// Types ==
typedef enum {
	AETypeReal, AETypeComplex, AETypeVector, AETypeString, AETypeLambda, AETypeRecipe
} AEType;

// Obj =====
typedef struct {
	Dim a;
	Dim b;
	Dim c;
	AEType type;
} Obj;

Obj AEObjReal(double r);
Obj AEObjComplex(double r, double i);
Obj AEObjVector(double x, double y,double z);
Obj AEObjString(char* string);
Obj AEObjMirror(Obj obj);
void AEObjWipe(Obj* obj);

char* Oovium_objToString(Obj obj);

// Stack ===
typedef struct Stack {
	Obj* stack;
	unsigned int sp;
	unsigned int sn;
} Stack;

Stack* AEStackCreate(unsigned int sn);
void AEStackRelease(Stack* stack);

// Pool ====
typedef struct Pool {
	Stack* rcp;
	Stack* lmb;
} Pool;

Pool* AEPoolThreadGet(void);

// Slot ====
typedef struct Slot {
	char* name;
	byte fixed;
	byte loaded;
	Obj obj;
	byte stacked;
	char offset;
} Slot;

// Memory ==
typedef struct Memory {
	Slot* slots;
	mnimi sn;
} Memory;

Memory* AEMemoryCreate(long sn);
Memory* AEMemoryCreateClone(Memory* memory);
void AEMemoryRelease(Memory* memory);
void AEMemorySetName(Memory* memory, mnimi index, char* name);
void AEMemorySetValue(Memory* memory, mnimi index, double value);
void AEMemoryMarkLoaded(Memory* memory, mnimi index);
void AEMemorySet(Memory* memory, mnimi index, Obj obj);
Obj AEMemoryGet(Memory* memory, mnimi index);
void AEMemoryFix(Memory* memory, mnimi index);
void AEMemoryUnfix(Memory* memory, mnimi index);
void AEMemoryClear(Memory* memory);
void AEMemoryNuke(Memory* memory);
void AEMemoryPrint(Memory* memory);
mnimi AEMemoryIndexForName(Memory* memory, char* name);
int AEMemorySearchForName(Memory* memory, char* name);
double AEMemoryValue(Memory* memory, mnimi index);
double AEMemoryValueForName(Memory* memory, char* name);
void AEMemoryLoad(Memory* memory, Memory* from);
byte AEMemoryLoaded(Memory* memory, mnimi index);
Obj AEMemoryMirror(Memory* memory, mnimi index);

// Lambda ==
typedef struct Lambda {
	Obj* constants;
	byte cn;
	
	mnimi* variables;
	byte vn;
	
	byte* morphs;
	byte mn;
	
	mnimi vi;
	char* label;
} Lambda;

Lambda* AELambdaCreate(mnimi vi, Obj* constants, byte cn, mnimi* variables, byte vn, byte* morphs, byte mn, char* label);
Lambda* AELambdaCreateClone(Lambda* lambda);
void AELambdaRelease(Lambda* lambda);
void AELambdaPrint(Lambda* lambda);
Obj AELambdaExecute(Lambda* lambda, Memory* memory);
Obj AEObjLambda(Lambda* lambda);

// Task ====
typedef enum AETask {
	AETaskLambda,
	AETaskGoto,
	AETaskIfGoto,
	AETaskFork,
	AETaskAssign,
	AETaskNull
} AETask;

typedef struct LambdaTask {
	Lambda* lambda;
} LambdaTask;
typedef struct GotoTask {
	byte go2;
} GotoTask;
typedef struct IfGotoTask {
	byte index;
	byte go2;
} IfGotoTask;
typedef struct ForkTask {
	byte ifIndex;
	byte thenIndex;
	byte elseIndex;
	byte resultIndex;
} ForkTask;
typedef struct AssignTask {
	byte fromIndex;
	byte toIndex;
} AssignTask;

typedef struct Task {
	AETask type;
	char* label;
	char* command;
	union {
		LambdaTask lambda;
		GotoTask go2;
		IfGotoTask ifGoto;
		ForkTask fork;
		AssignTask assign;
	};
} Task;

Task* AETaskCreateLambda(Lambda* lambda);
Task* AETaskCreateGoto(byte go2);
Task* AETaskCreateIfGoto(mnimi index,byte go2);
Task* AETaskCreateFork(mnimi ifIndex, mnimi thenIndex, mnimi elseIndex, mnimi resultIndex);
Task* AETaskCreateAssign(mnimi fromIndex, mnimi toIndex);
Task* AETaskCreateNull(void);
Task* AETaskCreateClone(Task* task);
void AETaskRelease(Task* task);
long AETaskExecute(Task* task, Memory* memory);
void AETaskSetLabels(Task* task, char* label, char* command);
void AETaskPrint(Task* task);

// Recipe ==
typedef struct Recipe {
	char* name;
	mnimi ri;					// result index
	Task** tasks;
	byte tn;					// number of tasks
	mnimi* params;				// parameter indexes
	byte pn;					// number of parameters
	Memory* memory;
	byte mn;					// number of memory slots used
} Recipe;

Recipe* AERecipeCreate(long tn);
Recipe* AERecipeCreateClone(Recipe* recipe);
void AERecipeRelease(Recipe* recipe);
void AERecipeSetName(Recipe* recipe, char* name);
void AERecipeSetMemory(Recipe* recipe, Memory* memory);
void AERecipeSignature(Recipe* recipe, mnimi ri, byte pn);
byte AERecipeExecute(Recipe* recipe, Memory* memory);
void AERecipePrint(Recipe* recipe);
Obj AEObjRecipe(Recipe* recipe);

void startAegean(void);

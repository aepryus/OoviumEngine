//
//  Aegean.c
//  Oovium
//
//  Created by Joe Charlier on 2/4/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

#include <math.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "Aegean.h"

// Obj =============================================================================================
Obj AEObjReal(double r) {
	Obj obj;
	obj.a.x = r;
	obj.type = AETypeReal;
	return obj;
}
Obj AEObjComplex(double r, double i) {
	Obj obj;
	obj.a.x = r;
	obj.b.x = i;
	obj.type = AETypeComplex;
	return obj;
}
Obj AEObjVector(double x, double y, double z) {
	Obj obj;
	obj.a.x = x;
	obj.b.x = y;
	obj.c.x = z;
	obj.type = AETypeVector;
	return obj;
}
Obj AEObjString(char* string) {
	Obj obj;
	obj.a.p = malloc(sizeof(char)*(strlen(string)+1));
    // Added because of a crash when using strings in an if() function.  This can be removed when the if is fixed.
    if (strlen(string) > 0)
        strcpy(obj.a.p, string);
	obj.type = AETypeString;
	return obj;
}
Obj AEObjLambda(Lambda* lambda) {
	Obj obj;
	obj.a.p = lambda;
	obj.type = AETypeLambda;
	return obj;
}
Obj AEObjRecipe(Recipe* recipe) {
	Obj obj;
	obj.a.p = recipe;
	obj.type = AETypeRecipe;
	return obj;
}
Obj AEMemoryMirror(Memory* memory, mnimi index) {
	Obj* obj = &memory->slots[index].obj;
	if (obj->type == AETypeString) {
		return AEObjString(obj->a.p);
	}
	return *obj;
}
Obj AEObjMirror(Obj obj) {
	if (obj.type == AETypeString) {
		return AEObjString(obj.a.p);
	}
	return obj;
}
void AEObjWipe(Obj* obj) {
	if (obj->type == AETypeString) {
		free(obj->a.p);
		obj->type = AETypeReal;
	}
}

// Stack ===========================================================================================
Stack* AEStackCreate(unsigned int sn) {
	Stack* stack = (Stack*)malloc(sizeof(Stack));
	stack->stack = (Obj*)malloc(sizeof(Obj)*sn);
	stack->sp = 0;
	stack->sn = sn;
	return stack;
}
void AEStackRelease(Stack* stack) {
	if (stack == 0) return;
	free(stack->stack);
	free(stack);
}
void AEStackPush(Stack* stack, Obj obj) {
	if (stack->sp >= stack->sn) abort();
	stack->stack[stack->sp] = obj;
	stack->sp++;
}
Obj AEStackPop(Stack* stack) {
	stack->sp--;
	if (stack->sp < 0) abort();
	return stack->stack[stack->sp];
}
Obj AEStackPeek(Stack* stack, int offset) {
	int index = (int)stack->sp+offset;
    if (index < 0 || index >= stack->sn) return AEObjReal(NAN);
	return stack->stack[index];
}
void AEStackPoke(Stack* stack, int offset, Obj obj) {
	int index = (int)stack->sp+offset;
	if (index < 0 || index >= stack->sn) abort();
	stack->stack[index] = obj;
}
void AEStackPrint(Stack* stack) {
	printf("[ Stack ==================== ]\n");
	printf("   sp: %d\n", stack->sp);
	printf("   sn: %d\n", stack->sn);
	printf("   stack:\n");
	for (int i=0;i<stack->sp;i++) {
		printf("    [%2d][%s]\n", i, Oovium_objToString(stack->stack[i]));
	}
	printf("[ =========================== ]\n\n");
}

// Memory ==========================================================================================
Memory* AEMemoryCreate(long sn) {
	Memory* memory = (Memory*)malloc(sizeof(Memory));
	memory->sn = sn;
	memory->slots = (Slot*)malloc(sizeof(Slot)*sn);

	for (int i=0;i<sn;i++) {
		memory->slots[i].name = malloc(sizeof(char));
		memory->slots[i].name[0] = 0;
		memory->slots[i].fixed = 0;
		memory->slots[i].loaded = 0;
		memory->slots[i].obj.a.x = 0;
		memory->slots[i].obj.type = AETypeReal;
		memory->slots[i].stacked = 0;
		memory->slots[i].offset = 0;
	}
	
	return memory;
}
Memory* AEMemoryCreateClone(Memory* memory) {
	Memory* clone = (Memory*)malloc(sizeof(Memory));
	clone->slots = (Slot*)malloc(sizeof(Slot)*memory->sn);
	clone->sn = memory->sn;

	for (int i=0;i<clone->sn;i++) {
		clone->slots[i].name = malloc(sizeof(char)*(strlen(memory->slots[i].name)+1));
		strcpy(clone->slots[i].name, memory->slots[i].name);
		clone->slots[i].fixed = memory->slots[i].fixed;
		clone->slots[i].loaded = memory->slots[i].loaded;
		clone->slots[i].obj = AEObjMirror(memory->slots[i].obj);
		clone->slots[i].stacked = memory->slots[i].stacked;
		clone->slots[i].offset = memory->slots[i].offset;
	}
	
	return clone;
}
void AEMemoryRelease(Memory* memory) {
	if (memory == 0) return;
	for (int i=0;i<memory->sn;i++) {
		free(memory->slots[i].name);
		AEObjWipe(&memory->slots[i].obj);
	}
	free(memory->slots);
	free(memory);
}
void AEMemorySetName(Memory* memory, mnimi index, char* name) {
	free(memory->slots[index].name);
	memory->slots[index].name = malloc(sizeof(char)*(strlen(name)+1));
	strcpy(memory->slots[index].name, name);
}
void AEMemorySet(Memory* memory, mnimi index, Obj obj) {
	if (!memory->slots[index].stacked)
		memory->slots[index].obj = obj;
	else
		AEStackPoke(AEPoolThreadGet()->rcp, memory->slots[index].offset, obj);
	memory->slots[index].loaded = 1;
}
void AEMemorySetValue(Memory* memory, mnimi index, double value) {
	memory->slots[index].obj.a.x = value;
	memory->slots[index].obj.type = AETypeReal;
	memory->slots[index].loaded = 1;
}
void AEMemoryMarkLoaded(Memory* memory, mnimi index) {
    if (memory->slots[index].loaded == 1) return;
    memory->slots[index].obj.a.x = 0;
    memory->slots[index].obj.type = AETypeReal;
    memory->slots[index].loaded = 1;
}
Obj AEMemoryGet(Memory* memory, mnimi index) {
	if (!memory->slots[index].stacked)
		return memory->slots[index].obj;
	else
		return AEStackPeek(AEPoolThreadGet()->rcp, memory->slots[index].offset);
}
void AEMemoryClear(Memory* memory) {
	for (int i=0;i<memory->sn;i++) {
		memory->slots[i].loaded = memory->slots[i].fixed;
		AEObjWipe(&memory->slots[i].obj);
	}
}
void AEMemoryLoad(Memory* memory, Memory* from) {
	for (int i=0;i<from->sn;i++) {
		int index = AEMemorySearchForName(memory, from->slots[i].name);
		if (index == -1) continue;
		memory->slots[index].fixed = from->slots[i].fixed;
		memory->slots[index].loaded = from->slots[i].loaded;
		memory->slots[index].obj = AEObjMirror(from->slots[i].obj);
	}
}
void AEMemoryFix(Memory* memory, mnimi index) {
	memory->slots[index].fixed = 1;
}
void AEMemoryUnfix(Memory* memory, mnimi index) {
	AEObjWipe(&memory->slots[index].obj);
	memory->slots[index].loaded = 0;
	memory->slots[index].fixed = 0;
}
void AEMemoryNuke(Memory* memory) {
	for (int i=0;i<memory->sn;i++) {
		memory->slots[i].fixed = 0;
		memory->slots[i].loaded = 0;
	}
}
mnimi AEMemoryIndexForName(Memory* memory, char* name) {
	for (mnimi i=0;i<memory->sn;i++) {
		if (strcmp(name, memory->slots[i].name) == 0)
			return i;
	}
//	return 255;
	abort();
}
int AEMemorySearchForName(Memory* memory, char* name) {
	for (int i=0;i<memory->sn;i++) {
		if (strcmp(name, memory->slots[i].name) == 0)
			return i;
	}
	return -1;
}
double AEMemoryValue(Memory* memory, mnimi index) {
	return memory->slots[index].obj.a.x;
}
double AEMemoryValueForName(Memory* memory, char* name) {
	return AEMemoryValue(memory, AEMemoryIndexForName(memory, name));
}
byte AEMemoryLoaded(Memory* memory, mnimi index) {
	return memory->slots[index].loaded;
}
void AEMemoryPrint(Memory* memory) {
	printf("[ Memory ======================================= ]\n\n");
    printf("  [In] [F] [L] [S] [Of] [Name          ] [Value]\n");
    printf("  ---- --- --- --- ---- ---------------- -------\n");
	for (int i=0;i<memory->sn;i++) {
		char value[32];
		if (memory->slots[i].loaded) {
			sprintf(value, "%s", Oovium_objToString(AEMemoryGet(memory, i)));
		} else
			sprintf(value, "-");
		printf("  [%2d] [%c] [%c] [%c] [%2d] [%-14s] [%s]\n", i, memory->slots[i].fixed?'X':' ', memory->slots[i].loaded?'X':' ', memory->slots[i].stacked?'X':' ', memory->slots[i].offset, memory->slots[i].name, value);
	}
	printf("\n[ ============================================== ]\n\n");
}

// Pool ============================================================================================
Pool* AEPoolCreate(void) {
	Pool* pool = (Pool*)malloc(sizeof(Pool));
	pool->rcp = AEStackCreate(1000);
	pool->lmb = AEStackCreate(1000);
	return pool;
}
void AEPoolRelease(Pool* pool) {
	AEStackRelease(pool->rcp);
	AEStackRelease(pool->lmb);
	free(pool);
}

pthread_key_t poolKey = 0;

Pool* AEPoolThreadGet(void) {
	Pool* pool = (Pool*)pthread_getspecific(poolKey);
	if (!pool) {
//		printf("[ Pool ===================== ]\n");
//		printf("   created [%d]\n\n", ++n);
		pool = AEPoolCreate();
		pthread_setspecific(poolKey, pool);
	}
	return pool;
}
void AEPoolThreadRelease(void* value) {
//	printf("[ Pool ===================== ]\n");
//	printf("   released [%d]\n\n", --n);
	Pool* pool = (Pool*)value;
	AEPoolRelease(pool);
	pthread_setspecific(poolKey, NULL);
}
void AEPoolThreadInit(void) {
	int error = pthread_key_create(&poolKey, AEPoolThreadRelease);
	if (error)
		printf("AEPoolThreadInit() pthread_key_create failed [ %d ]", error);
}

// Lambda ==========================================================================================
Lambda* AELambdaCreate(mnimi vi, Obj* constants, byte cn, mnimi* variables, byte vn, byte* morphs, byte mn, char* label) {
	Lambda* lambda = (Lambda*)malloc(sizeof(Lambda));
	
	lambda->vi = vi;
	
	if (mn > 0) {
		lambda->constants = (Obj*)malloc(sizeof(Obj)*cn);
		for (int i=0;i<cn;i++)
			lambda->constants[i] = constants[i];
		lambda->cn = cn;
	
		lambda->variables = (mnimi*)malloc(sizeof(mnimi)*vn);
		for (int i=0;i<vn;i++)
			lambda->variables[i] = variables[i];
		lambda->vn = vn;
	
		lambda->morphs = (byte*)malloc(sizeof(byte)*mn);
		for (int i=0;i<mn;i++)
			lambda->morphs[i] = morphs[i];
		lambda->mn = mn;
		
		if (label) {
			lambda->label = (char*)malloc(sizeof(char)*(strlen(label)+1));
			strcpy(lambda->label, label);
		} else
			lambda->label = 0;
		
	} else {
		lambda->constants = (Obj*)malloc(sizeof(Obj));
		lambda->constants[0] = AEObjReal(0);
		lambda->cn = 1;
		lambda->variables = (mnimi*)malloc(0);
		lambda->vn = 0;
		lambda->morphs = (byte*)malloc(sizeof(byte));
		lambda->morphs[0] = AEMorphNumCns;
		lambda->mn = 1;
		lambda->label = 0;
	}
	
	return lambda;
}
Lambda* AELambdaCreateClone(Lambda* lambda) {
	Lambda* clone = (Lambda*)malloc(sizeof(Lambda));
	
	clone->vi = lambda->vi;
	
	clone->constants = (Obj*)malloc(sizeof(Obj)*lambda->cn);
	for (int i=0;i<lambda->cn;i++)
		clone->constants[i] = lambda->constants[i];
	clone->cn = lambda->cn;
	
	clone->variables = (mnimi*)malloc(sizeof(mnimi)*lambda->vn);
	for (int i=0;i<lambda->vn;i++)
		clone->variables[i] = lambda->variables[i];
	clone->vn = lambda->vn;
	
	clone->morphs = (byte*)malloc(sizeof(byte)*lambda->mn);
	for (int i=0;i<lambda->mn;i++)
		clone->morphs[i] = lambda->morphs[i];
	clone->mn = lambda->mn;
	
	if (lambda->label) {
		clone->label = (char*)malloc(sizeof(char)*(strlen(lambda->label)+1));
		strcpy(clone->label, lambda->label);
	} else
		clone->label = 0;
	
	return clone;
}
void AELambdaRelease(Lambda* lambda) {
	if (lambda == 0) return;
	free(lambda->constants);
	free(lambda->variables);
	free(lambda->morphs);
	free(lambda->label);
	free(lambda);
}
void AELambdaPrint(Lambda* lambda) {
	printf("[ Lambda ==================== ]\n");
	printf("  index: %d\n", lambda->vi);
	if (lambda->label)
		printf("  label: %s\n", lambda->label);
	printf("  constants:\n");
	for (int i=0;i<lambda->cn;i++)
		printf("  [%2d][%s]\n", i, Oovium_objToString(lambda->constants[i]));
	printf("  variables:\n");
	for (int i=0;i<lambda->vn;i++)
		printf("  [%2d][%2d]\n", i, lambda->variables[i]);
	printf("  morphs:\n");
	for (int i=0;i<lambda->mn;i++)
		printf("  [%2d][%2d]\n", i, lambda->morphs[i]);
	printf("[ =========================== ]\n\n");
}
void AECastNumToCpx(Obj *obj) {
	if (obj->type == AETypeComplex) return;
	obj->type = AETypeComplex;
	obj->b.x = 0;
}
Obj AELambdaExecute(Lambda* lambda, Memory* memory) {
	Pool* pool = AEPoolThreadGet();
	Stack* rcp = pool->rcp;
	Stack* lmb = pool->lmb;

	byte cp = 0;
	byte vp = 0;
	
	for (int i=0;i<lambda->mn;i++) {
		switch (lambda->morphs[i]) {
			case AEMorphAdd: {
				lmb->stack[lmb->sp-2].a.x += lmb->stack[lmb->sp-1].a.x;
				lmb->sp--;
			} break;

			case AEMorphSub: {
				lmb->stack[lmb->sp-2].a.x -= lmb->stack[lmb->sp-1].a.x;
				lmb->sp--;
			} break;

			case AEMorphMul: {
				lmb->stack[lmb->sp-2].a.x *= lmb->stack[lmb->sp-1].a.x;
				lmb->sp--;
			} break;

			case AEMorphDiv: {
				lmb->stack[lmb->sp-2].a.x /= lmb->stack[lmb->sp-1].a.x;
				lmb->sp--;
			} break;

			case AEMorphMod: {
				lmb->stack[lmb->sp-2].a.x = (int)lmb->stack[lmb->sp-2].a.x % (int)lmb->stack[lmb->sp-1].a.x;
				lmb->sp--;
			} break;
				
			case AEMorphPow: {
				lmb->stack[lmb->sp-2].a.x = pow(lmb->stack[lmb->sp-2].a.x,lmb->stack[lmb->sp-1].a.x);
				lmb->sp--;
			} break;

			case AEMorphEqual: {
				lmb->stack[lmb->sp-2].a.x = (lmb->stack[lmb->sp-2].a.x == lmb->stack[lmb->sp-1].a.x);
				lmb->sp--;
			} break;

			case AEMorphNotEqual: {
				lmb->stack[lmb->sp-2].a.x = (lmb->stack[lmb->sp-2].a.x != lmb->stack[lmb->sp-1].a.x);
				lmb->sp--;
			} break;
				
			case AEMorphLessThan: {
				lmb->stack[lmb->sp-2].a.x = (lmb->stack[lmb->sp-2].a.x < lmb->stack[lmb->sp-1].a.x);
				lmb->sp--;
			} break;

			case AEMorphLessThanOrEqual: {
				lmb->stack[lmb->sp-2].a.x = (lmb->stack[lmb->sp-2].a.x <= lmb->stack[lmb->sp-1].a.x);
				lmb->sp--;
			} break;

			case AEMorphGreaterThan: {
				lmb->stack[lmb->sp-2].a.x = (lmb->stack[lmb->sp-2].a.x > lmb->stack[lmb->sp-1].a.x);
				lmb->sp--;
			} break;

			case AEMorphGreaterThanOrEqual: {
				lmb->stack[lmb->sp-2].a.x = (lmb->stack[lmb->sp-2].a.x >= lmb->stack[lmb->sp-1].a.x);
				lmb->sp--;
			} break;
				
			case AEMorphAnd: {
				lmb->stack[lmb->sp-2].a.x = (lmb->stack[lmb->sp-2].a.x && lmb->stack[lmb->sp-1].a.x);
				lmb->sp--;
			} break;

			case AEMorphOr: {
				lmb->stack[lmb->sp-2].a.x = (lmb->stack[lmb->sp-2].a.x || lmb->stack[lmb->sp-1].a.x);
				lmb->sp--;
			} break;

			case AEMorphNeg: {
				lmb->stack[lmb->sp-1].a.x = -lmb->stack[lmb->sp-1].a.x;
			} break;

			case AEMorphNot: {
				lmb->stack[lmb->sp-1].a.x = !lmb->stack[lmb->sp-1].a.x;
			} break;
				
			case AEMorphAbs: {
				lmb->stack[lmb->sp-1].a.x = fabs(lmb->stack[lmb->sp-1].a.x);
			} break;
				
			case AEMorphRound: {
				lmb->stack[lmb->sp-1].a.x = round(lmb->stack[lmb->sp-1].a.x);
			} break;
				
			case AEMorphFloor: {
				lmb->stack[lmb->sp-1].a.x = floor(lmb->stack[lmb->sp-1].a.x);
			} break;
				
			case AEMorphSqrt: {
				lmb->stack[lmb->sp-1].a.x = sqrt(lmb->stack[lmb->sp-1].a.x);
			} break;
				
			case AEMorphFac: {
				int i = lmb->stack[lmb->sp-1].a.x;
				double n = 1;
				while (i>1) n *= i--;
				lmb->stack[lmb->sp-1].a.x = n;
			} break;
				
			case AEMorphExp: {
				lmb->stack[lmb->sp-1].a.x = exp(lmb->stack[lmb->sp-1].a.x);
			} break;
				
			case AEMorphLn: {
				lmb->stack[lmb->sp-1].a.x = log(lmb->stack[lmb->sp-1].a.x);
			} break;
				
			case AEMorphLog: {
				lmb->stack[lmb->sp-1].a.x = log10(lmb->stack[lmb->sp-1].a.x);
			} break;
				
			case AEMorphTen: {
				lmb->stack[lmb->sp-1].a.x = pow(10, lmb->stack[lmb->sp-1].a.x);
			} break;
				
			case AEMorphTwo: {
				lmb->stack[lmb->sp-1].a.x = pow(2, lmb->stack[lmb->sp-1].a.x);
			} break;
				
			case AEMorphLog2: {
				lmb->stack[lmb->sp-1].a.x = log2(lmb->stack[lmb->sp-1].a.x);
			} break;
				
			case AEMorphSin: {
				lmb->stack[lmb->sp-1].a.x = sin(lmb->stack[lmb->sp-1].a.x);
			} break;
				
			case AEMorphCos: {
				lmb->stack[lmb->sp-1].a.x = cos(lmb->stack[lmb->sp-1].a.x);
			} break;
				
			case AEMorphTan: {
				lmb->stack[lmb->sp-1].a.x = tan(lmb->stack[lmb->sp-1].a.x);
			} break;
				
			case AEMorphAsin: {
				lmb->stack[lmb->sp-1].a.x = asin(lmb->stack[lmb->sp-1].a.x);
			} break;
				
			case AEMorphAcos: {
				lmb->stack[lmb->sp-1].a.x = acos(lmb->stack[lmb->sp-1].a.x);
			} break;
				
			case AEMorphAtan: {
				lmb->stack[lmb->sp-1].a.x = atan(lmb->stack[lmb->sp-1].a.x);
			} break;
				
			case AEMorphSec: {
				lmb->stack[lmb->sp-1].a.x = 1/cos(lmb->stack[lmb->sp-1].a.x);
			} break;
				
			case AEMorphCsc: {
				lmb->stack[lmb->sp-1].a.x = 1/sin(lmb->stack[lmb->sp-1].a.x);
			} break;
				
			case AEMorphCot: {
				lmb->stack[lmb->sp-1].a.x = 1/tan(lmb->stack[lmb->sp-1].a.x);
			} break;
				
			case AEMorphSinh: {
				lmb->stack[lmb->sp-1].a.x = sinh(lmb->stack[lmb->sp-1].a.x);
			} break;
				
			case AEMorphCosh: {
				lmb->stack[lmb->sp-1].a.x = cosh(lmb->stack[lmb->sp-1].a.x);
			} break;
				
			case AEMorphTanh: {
				lmb->stack[lmb->sp-1].a.x = tanh(lmb->stack[lmb->sp-1].a.x);
			} break;
				
			case AEMorphAsinh: {
				lmb->stack[lmb->sp-1].a.x = asinh(lmb->stack[lmb->sp-1].a.x);
			} break;
				
			case AEMorphAcosh: {
				lmb->stack[lmb->sp-1].a.x = acosh(lmb->stack[lmb->sp-1].a.x);
			} break;
				
			case AEMorphAtanh: {
				lmb->stack[lmb->sp-1].a.x = atanh(lmb->stack[lmb->sp-1].a.x);
			} break;
				
			case AEMorphIf: {
				lmb->stack[lmb->sp-3].a.x = lmb->stack[lmb->sp-3].a.x ? lmb->stack[lmb->sp-2].a.x : lmb->stack[lmb->sp-1].a.x;
				lmb->sp -= 2;
			} break;

			case AEMorphMin: {
				lmb->stack[lmb->sp-2].a.x = lmb->stack[lmb->sp-2].a.x < lmb->stack[lmb->sp-1].a.x ? lmb->stack[lmb->sp-2].a.x : lmb->stack[lmb->sp-1].a.x;
				lmb->sp--;
			} break;
				
			case AEMorphMax: {
				lmb->stack[lmb->sp-2].a.x = lmb->stack[lmb->sp-2].a.x > lmb->stack[lmb->sp-1].a.x ? lmb->stack[lmb->sp-2].a.x : lmb->stack[lmb->sp-1].a.x;
				lmb->sp--;
			} break;
				
			case AEMorphSum: {
				Recipe* recipe = lmb->stack[lmb->sp-1].a.p;
				double sum = 0;
				for (double x = lmb->stack[lmb->sp-3].a.x;x <= lmb->stack[lmb->sp-2].a.x;x++) {
					rcp->sp += recipe->mn;
					AEMemorySet(recipe->memory, recipe->params[0], AEObjReal(x));
					byte complete = AERecipeExecute(recipe, recipe->memory);
					
					if (!complete) {sum = NAN;break;}
					sum += AEMemoryGet(recipe->memory, recipe->ri).a.x;
					rcp->sp -= recipe->mn;
					AEMemoryClear(recipe->memory);
				}
				lmb->stack[lmb->sp-3].a.x = sum;
				lmb->sp -= 2;
			} break;
			
			case AEMorphRandom: {
				u_int32_t n = lmb->stack[lmb->sp-1].a.x;
				lmb->stack[lmb->sp-1].a.x = arc4random() % n;
			} break;

			case AEMorphNumCns: case AEMorphCpxCns: case AEMorphVctCns: case AEMorphLmbCns: {
				lmb->stack[lmb->sp] = lambda->constants[cp];
				lmb->sp++;
				cp++;
			} break;
				
			case AEMorphNumVar: case AEMorphCpxVar: case AEMorphVctVar: case AEMorphLmbVar: case AEMorphRcpVar: {
				lmb->stack[lmb->sp] = AEMemoryGet(memory, lambda->variables[vp]);
				lmb->sp++;
				vp++;
			} break;
			
			case AEMorphNumVarForce: {
				lmb->stack[lmb->sp] = AEMemoryGet(memory, lambda->variables[vp]);
				lmb->stack[lmb->sp].type = AETypeReal;
				lmb->sp++;
				vp++;
			} break;

			case AEMorphStrCns: {
				lmb->stack[lmb->sp] = AEObjMirror(lambda->constants[cp]);
				lmb->sp++;
				cp++;
			} break;
				
			case AEMorphStrVar: {
				lmb->stack[lmb->sp] = AEObjMirror(AEMemoryGet(memory, lambda->variables[vp]));
				lmb->sp++;
				vp++;
			} break;

			case AEMorphComplex: {
				lmb->stack[lmb->sp-2].a.x = lmb->stack[lmb->sp-2].a.x;
				lmb->stack[lmb->sp-2].b.x = lmb->stack[lmb->sp-1].a.x;
				lmb->stack[lmb->sp-2].type = AETypeComplex;
				lmb->sp--;
			} break;
				
			case AEMorphCpxAdd: {
				AECastNumToCpx(&lmb->stack[lmb->sp-2]);
				AECastNumToCpx(&lmb->stack[lmb->sp-1]);
				lmb->stack[lmb->sp-2].a.x += lmb->stack[lmb->sp-1].a.x;
				lmb->stack[lmb->sp-2].b.x += lmb->stack[lmb->sp-1].b.x;
				lmb->sp--;
			} break;
				
			case AEMorphCpxSub: {
				AECastNumToCpx(&lmb->stack[lmb->sp-2]);
				AECastNumToCpx(&lmb->stack[lmb->sp-1]);
				lmb->stack[lmb->sp-2].a.x -= lmb->stack[lmb->sp-1].a.x;
				lmb->stack[lmb->sp-2].b.x -= lmb->stack[lmb->sp-1].b.x;
				lmb->sp--;
			} break;
				
			case AEMorphCpxMul: {
				AECastNumToCpx(&lmb->stack[lmb->sp-2]);
				AECastNumToCpx(&lmb->stack[lmb->sp-1]);
				double Ar = lmb->stack[lmb->sp-2].a.x;
				double Ai = lmb->stack[lmb->sp-2].b.x;
				double Br = lmb->stack[lmb->sp-1].a.x;
				double Bi = lmb->stack[lmb->sp-1].b.x;
				lmb->stack[lmb->sp-2].a.x = Ar*Br-Ai*Bi;
				lmb->stack[lmb->sp-2].b.x = Ar*Bi+Br*Ai;
				lmb->sp--;
			} break;
				
			case AEMorphCpxDiv: {
				AECastNumToCpx(&lmb->stack[lmb->sp-2]);
				AECastNumToCpx(&lmb->stack[lmb->sp-1]);
				double Ar = lmb->stack[lmb->sp-2].a.x;
				double Ai = lmb->stack[lmb->sp-2].b.x;
				double Br = lmb->stack[lmb->sp-1].a.x;
				double Bi = lmb->stack[lmb->sp-1].b.x;
				double denomenator = Br*Br+Bi*Bi;
				lmb->stack[lmb->sp-2].a.x = (Ar*Br+Ai*Bi)/denomenator;
				lmb->stack[lmb->sp-2].b.x = (Ai*Br-Ar*Bi)/denomenator;
				lmb->sp--;
			} break;
				
			case AEMorphCpxPow: {
				AECastNumToCpx(&lmb->stack[lmb->sp-2]);
				AECastNumToCpx(&lmb->stack[lmb->sp-1]);
				double Ar = lmb->stack[lmb->sp-2].a.x;
				double Ai = lmb->stack[lmb->sp-2].b.x;
				double Br = lmb->stack[lmb->sp-1].a.x;
				double Bi = lmb->stack[lmb->sp-1].b.x;
				double r = sqrt(Ar*Ar+Ai*Ai);
				double s = atan2(Ai,Ar);
				double x = pow(r,Br)*exp(-s*Bi);
				double y = Bi*log(r)+Br*s;
				lmb->stack[lmb->sp-2].a.x = x*cos(y);
				lmb->stack[lmb->sp-2].b.x = x*sin(y);
				lmb->sp--;
			} break;

			case AEMorphCpxEqual: {
				AECastNumToCpx(&lmb->stack[lmb->sp-2]);
				AECastNumToCpx(&lmb->stack[lmb->sp-1]);
				double Ar = lmb->stack[lmb->sp-2].a.x;
				double Ai = lmb->stack[lmb->sp-2].b.x;
				double Br = lmb->stack[lmb->sp-1].a.x;
				double Bi = lmb->stack[lmb->sp-1].b.x;
				lmb->stack[lmb->sp-2].a.x = Ar == Br && Ai == Bi;
				lmb->stack[lmb->sp-2].type = AETypeReal;
				lmb->sp--;
			} break;
				
			case AEMorphCpxNotEqual: {
				AECastNumToCpx(&lmb->stack[lmb->sp-2]);
				AECastNumToCpx(&lmb->stack[lmb->sp-1]);
				double Ar = lmb->stack[lmb->sp-2].a.x;
				double Ai = lmb->stack[lmb->sp-2].b.x;
				double Br = lmb->stack[lmb->sp-1].a.x;
				double Bi = lmb->stack[lmb->sp-1].b.x;
				lmb->stack[lmb->sp-2].a.x = Ar != Br || Ai != Bi;
				lmb->stack[lmb->sp-2].type = AETypeReal;
				lmb->sp--;
			} break;

			case AEMorphCpxSin: {
				double r = lmb->stack[lmb->sp-1].a.x;
				double i = lmb->stack[lmb->sp-1].b.x;
				double x = exp(i);
				double y = 1/x;
				lmb->stack[lmb->sp-1].a.x = sin(r)*(x+y)/2;
				lmb->stack[lmb->sp-1].b.x = cos(r)*(x-y)/2;
			} break;

			case AEMorphCpxCos: {
				double r = lmb->stack[lmb->sp-1].a.x;
				double i = lmb->stack[lmb->sp-1].b.x;
				double x = exp(i);
				double y = 1/x;
				lmb->stack[lmb->sp-1].a.x = cos(r)*(x+y)/2;
				lmb->stack[lmb->sp-1].b.x = sin(r)*(y-x)/2;
			} break;

			case AEMorphCpxTan: {
				double r = lmb->stack[lmb->sp-1].a.x;
				double i = lmb->stack[lmb->sp-1].b.x;
				double ei = exp(i);
				double ie = 1/ei;
				double s = ei+ie;
				double d = ei-ie;
				double sr = sin(r);
				double cr = cos(r);
				double s2 = s*s;
				double d2 = d*d;
				double denom = sr*sr*d2+cr*cr*s2;
				lmb->stack[lmb->sp-1].a.x = (s2-d2)*sr*cr/denom;
				lmb->stack[lmb->sp-1].b.x = s*d/denom;
			} break;

			case AEMorphCpxLn: {
				double r = lmb->stack[lmb->sp-1].a.x;
				double i = lmb->stack[lmb->sp-1].b.x;
				lmb->stack[lmb->sp-1].a.x = log(sqrt(r*r+i*i));
				lmb->stack[lmb->sp-1].b.x = atan2(i,r);
			} break;

			case AEMorphCpxExp: {
				double r = lmb->stack[lmb->sp-1].a.x;
				double i = lmb->stack[lmb->sp-1].b.x;
				double x = exp(r);
				lmb->stack[lmb->sp-1].a.x = x*cos(i);
				lmb->stack[lmb->sp-1].b.x = x*sin(i);
			} break;

			case AEMorphCpxSqrt: {
				double r = lmb->stack[lmb->sp-1].a.x;
				double i = lmb->stack[lmb->sp-1].b.x;
				double m = sqrt(r*r+i*i);
				lmb->stack[lmb->sp-1].a.x = sqrt((r+m)/2);
				lmb->stack[lmb->sp-1].b.x = (i<0?-1:1)*sqrt((-r+m)/2);
			} break;

			case AEMorphCpxAbs: {
				double r = lmb->stack[lmb->sp-1].a.x;
				double i = lmb->stack[lmb->sp-1].b.x;
				lmb->stack[lmb->sp-1].a.x = sqrt(r*r+i*i);
				lmb->stack[lmb->sp-1].type = AETypeReal;
			} break;

			case AEMorphCpxRound: {
				double r = lmb->stack[lmb->sp-1].a.x;
				double i = lmb->stack[lmb->sp-1].b.x;
				lmb->stack[lmb->sp-1].a.x = round(r);
				lmb->stack[lmb->sp-1].b.x = round(i);
			} break;

			case AEMorphCpxFloor: {
				double r = lmb->stack[lmb->sp-1].a.x;
				double i = lmb->stack[lmb->sp-1].b.x;
				lmb->stack[lmb->sp-1].a.x = floor(r);
				lmb->stack[lmb->sp-1].b.x = floor(i);
			} break;
				
			case AEMorphVector: {
				lmb->stack[lmb->sp-3].a.x = lmb->stack[lmb->sp-3].a.x;
				lmb->stack[lmb->sp-3].b.x = lmb->stack[lmb->sp-2].a.x;
				lmb->stack[lmb->sp-3].c.x = lmb->stack[lmb->sp-1].a.x;
				lmb->stack[lmb->sp-3].type = AETypeVector;
				lmb->sp -= 2;
			} break;
				
			case AEMorphVctAdd: {
				double Ax = lmb->stack[lmb->sp-2].a.x;
				double Ay = lmb->stack[lmb->sp-2].b.x;
				double Az = lmb->stack[lmb->sp-2].c.x;
				double Bx = lmb->stack[lmb->sp-1].a.x;
				double By = lmb->stack[lmb->sp-1].b.x;
				double Bz = lmb->stack[lmb->sp-1].c.x;
				lmb->stack[lmb->sp-2].a.x = Ax+Bx;
				lmb->stack[lmb->sp-2].b.x = Ay+By;
				lmb->stack[lmb->sp-2].c.x = Az+Bz;
				lmb->sp--;
			} break;

			case AEMorphVctSub: {
				double Ax = lmb->stack[lmb->sp-2].a.x;
				double Ay = lmb->stack[lmb->sp-2].b.x;
				double Az = lmb->stack[lmb->sp-2].c.x;
				double Bx = lmb->stack[lmb->sp-1].a.x;
				double By = lmb->stack[lmb->sp-1].b.x;
				double Bz = lmb->stack[lmb->sp-1].c.x;
				lmb->stack[lmb->sp-2].a.x = Ax-Bx;
				lmb->stack[lmb->sp-2].b.x = Ay-By;
				lmb->stack[lmb->sp-2].c.x = Az-Bz;
				lmb->sp--;
			} break;

			case AEMorphVctMulL: {
				double a = lmb->stack[lmb->sp-2].a.x;
				double x = lmb->stack[lmb->sp-1].a.x;
				double y = lmb->stack[lmb->sp-1].b.x;
				double z = lmb->stack[lmb->sp-1].c.x;
				lmb->stack[lmb->sp-2].a.x = a*x;
				lmb->stack[lmb->sp-2].b.x = a*y;
				lmb->stack[lmb->sp-2].c.x = a*z;
				lmb->stack[lmb->sp-2].type = AETypeVector;
				lmb->sp--;
			} break;

			case AEMorphVctMulR: {
				double x = lmb->stack[lmb->sp-2].a.x;
				double y = lmb->stack[lmb->sp-2].b.x;
				double z = lmb->stack[lmb->sp-2].c.x;
				double a = lmb->stack[lmb->sp-1].a.x;
				lmb->stack[lmb->sp-2].a.x = x*a;
				lmb->stack[lmb->sp-2].b.x = y*a;
				lmb->stack[lmb->sp-2].c.x = z*a;
				lmb->sp--;
			} break;
				
			case AEMorphVctDot: {
				double Ax = lmb->stack[lmb->sp-2].a.x;
				double Ay = lmb->stack[lmb->sp-2].b.x;
				double Az = lmb->stack[lmb->sp-2].c.x;
				double Bx = lmb->stack[lmb->sp-1].a.x;
				double By = lmb->stack[lmb->sp-1].b.x;
				double Bz = lmb->stack[lmb->sp-1].c.x;
				lmb->stack[lmb->sp-2].a.x = Ax*Bx+Ay*By+Az*Bz;
				lmb->stack[lmb->sp-2].type = AETypeReal;
				lmb->sp--;
			} break;

			case AEMorphVctCross: {
				double Ax = lmb->stack[lmb->sp-2].a.x;
				double Ay = lmb->stack[lmb->sp-2].b.x;
				double Az = lmb->stack[lmb->sp-2].c.x;
				double Bx = lmb->stack[lmb->sp-1].a.x;
				double By = lmb->stack[lmb->sp-1].b.x;
				double Bz = lmb->stack[lmb->sp-1].c.x;
				lmb->stack[lmb->sp-2].a.x = Ay*Bz-Az*By;
				lmb->stack[lmb->sp-2].b.x = Az*Bx-Ax*Bz;
				lmb->stack[lmb->sp-2].c.x = Ax*By-Ay*Bx;
				lmb->sp--;
			} break;

			case AEMorphVctNeg: {
				double x = lmb->stack[lmb->sp-1].a.x;
				double y = lmb->stack[lmb->sp-1].b.x;
				double z = lmb->stack[lmb->sp-1].c.x;
				lmb->stack[lmb->sp-1].a.x = -x;
				lmb->stack[lmb->sp-1].b.x = -y;
				lmb->stack[lmb->sp-1].c.x = -z;
			} break;
				
			case AEMorphStrAdd: {
				char* a;
				if (lmb->stack[lmb->sp-2].type == AETypeString)
					a = lmb->stack[lmb->sp-2].a.p;
				else {
					a = Oovium_objToString(lmb->stack[lmb->sp-2]);
				}
				char* b;
				if (lmb->stack[lmb->sp-1].type == AETypeString)
					b = lmb->stack[lmb->sp-1].a.p;
				else {
					b = Oovium_objToString(lmb->stack[lmb->sp-1]);
				}
				
				char* result = (char*)malloc(sizeof(char)*(strlen(a)+strlen(b)+1));
				strcat(result, a);
				strcat(result, b);
				
				AEObjWipe(&lmb->stack[lmb->sp-2]);
				AEObjWipe(&lmb->stack[lmb->sp-1]);
				
				lmb->stack[lmb->sp-2] = AEObjString(result);
				
				free(result);
				
				lmb->sp--;
			} break;
			
			case AEMorphLmbIf: {
				Lambda* thenLambda = lmb->stack[lmb->sp-2].a.p;
				Lambda* elseLambda = lmb->stack[lmb->sp-1].a.p;
				double ifValue = lmb->stack[lmb->sp-3].a.x;
				double result;
				if (ifValue) result = AELambdaExecute(thenLambda, memory).a.x;
				else result = AELambdaExecute(elseLambda, memory).a.x;
				lmb->stack[lmb->sp-3].a.x = result;
				lmb->sp -= 2;
			} break;
			
			case AEMorphLmbSum: {
				int ki = AEMemoryIndexForName(memory, "k");
				Lambda* lambda = lmb->stack[lmb->sp-1].a.p;
				double sum = 0;
				for (double x = lmb->stack[lmb->sp-3].a.x;x <= lmb->stack[lmb->sp-2].a.x;x++) {
					AEMemorySetValue(memory, ki, x);
					sum += AELambdaExecute(lambda, memory).a.x;
				}
				lmb->stack[lmb->sp-3].a.x = sum;
				lmb->sp -= 2;
			} break;

			case AEMorphRecipe: {
				Obj obj = AEMemoryGet(memory, lambda->variables[vp]);
				vp++;
				Recipe* recipe = (Recipe*)obj.a.p;
				rcp->sp += recipe->mn;
				for (int i=0;i<recipe->pn;i++)
					AEMemorySet(recipe->memory, recipe->params[i], lmb->stack[lmb->sp-recipe->pn+i]);
				byte complete = AERecipeExecute(recipe, recipe->memory);
				lmb->sp -= recipe->pn;
				if (complete)
					lmb->stack[lmb->sp] = AEMemoryGet(recipe->memory, recipe->ri);
				else
					lmb->stack[lmb->sp].a.x = NAN;
				rcp->sp -= recipe->mn;
				if (rcp->sp < 0) abort();
				lmb->sp++;
				AEMemoryClear(recipe->memory);
			} break;
				
			default: {
				abort();
			} break;
		}
	}

	lmb->sp--;
	
	return lmb->stack[lmb->sp];
}

// Task ============================================================================================
Task* AETaskCreateLambda(Lambda* lambda) {
	Task* task = (Task*)malloc(sizeof(Task));
	task->type = AETaskLambda;
	task->label = malloc(sizeof(char));
	task->label[0] = 0;
	task->command = malloc(sizeof(char));
	task->command[0] = 0;
	task->lambda.lambda = lambda;
	return task;
}
Task* AETaskCreateGoto(byte go2) {
	Task* task = (Task*)malloc(sizeof(Task));
	task->type = AETaskGoto;
	task->label = malloc(sizeof(char));
	task->label[0] = 0;
	task->command = malloc(sizeof(char));
	task->command[0] = 0;
	task->go2.go2 = go2;
	return task;
}
Task* AETaskCreateIfGoto(mnimi index,byte go2) {
	Task* task = (Task*)malloc(sizeof(Task));
	task->type = AETaskIfGoto;
	task->label = malloc(sizeof(char));
	task->label[0] = 0;
	task->command = malloc(sizeof(char));
	task->command[0] = 0;
	task->ifGoto.index = index;
	task->ifGoto.go2 = go2;
	return task;
}
Task* AETaskCreateFork(mnimi ifIndex, mnimi thenIndex, mnimi elseIndex, mnimi resultIndex) {
	Task* task = (Task*)malloc(sizeof(Task));
	task->type = AETaskFork;
	task->label = malloc(sizeof(char));
	task->label[0] = 0;
	task->command = malloc(sizeof(char));
	task->command[0] = 0;
	task->fork.ifIndex = ifIndex;
	task->fork.thenIndex = thenIndex;
	task->fork.elseIndex = elseIndex;
	task->fork.resultIndex = resultIndex;
	return task;
}
Task* AETaskCreateAssign(mnimi fromIndex, mnimi toIndex) {
	Task* task = (Task*)malloc(sizeof(Task));
	task->type = AETaskAssign;
	task->label = malloc(sizeof(char));
	task->label[0] = 0;
	task->command = malloc(sizeof(char));
	task->command[0] = 0;
	task->assign.fromIndex = fromIndex;
	task->assign.toIndex = toIndex;
	return task;
}
Task* AETaskCreateNull() {
	Task* task = (Task*)malloc(sizeof(Task));
	task->type = AETaskNull;
	task->label = malloc(sizeof(char));
	task->label[0] = 0;
	task->command = malloc(sizeof(char));
	task->command[0] = 0;
	return task;
}
Task* AETaskCreateClone(Task* task) {
	Task* clone = (Task*)malloc(sizeof(Task));
	clone->type = task->type;
	clone->label = malloc(sizeof(char)*(strlen(task->label)+1));
	clone->command = malloc(sizeof(char)*(strlen(task->command)+1));
	strcpy(clone->label, task->label);
	strcpy(clone->command, task->command);
	switch (clone->type) {
		case AETaskLambda: {
			clone->lambda.lambda = AELambdaCreateClone(task->lambda.lambda);
		} break;
		case AETaskGoto: {
			clone->go2.go2 = task->go2.go2;
		} break;
		case AETaskIfGoto: {
			clone->ifGoto.index = task->ifGoto.index;
			clone->ifGoto.go2 = task->ifGoto.go2;
		} break;
		case AETaskFork: {
			clone->fork.ifIndex = task->fork.ifIndex;
			clone->fork.thenIndex = task->fork.thenIndex;
			clone->fork.elseIndex = task->fork.elseIndex;
			clone->fork.resultIndex = task->fork.resultIndex;
		} break;
		case AETaskAssign: {
			clone->assign.fromIndex = task->assign.fromIndex;
			clone->assign.toIndex = task->assign.toIndex;
		} break;
		case AETaskNull: {
		} break;
	}

	return clone;
}
void AETaskRelease(Task* task) {
	if (task == 0) return;
	if (task->type == AETaskLambda)
		AELambdaRelease(task->lambda.lambda);
	free(task->label);
	free(task->command);
	free(task);
}

long AETaskExecute(Task* task, Memory* memory) {
	switch (task->type) {
		case AETaskLambda: {
			AEMemorySet(memory, task->lambda.lambda->vi, AEObjMirror(AELambdaExecute(task->lambda.lambda, memory)));
			return -1;
		} break;
		case AETaskGoto: {
			return task->go2.go2;
		} break;
		case AETaskIfGoto: {
			if (AEMemoryGet(memory, task->ifGoto.index).a.x != 0) return -1;
			return task->ifGoto.go2;
		} break;
		case AETaskFork: {
			if (AEMemoryGet(memory, task->fork.ifIndex).a.x != 0)
				AEMemorySet(memory, task->fork.resultIndex, AEObjMirror(AEMemoryGet(memory, task->fork.thenIndex)));
			else
				AEMemorySet(memory, task->fork.resultIndex, AEObjMirror(AEMemoryGet(memory, task->fork.elseIndex)));
			return -1;
		} break;
		case AETaskAssign: {
			AEMemorySet(memory, task->assign.toIndex, AEObjMirror(AEMemoryGet(memory, task->assign.fromIndex)));
			return -1;
		} break;
		case AETaskNull: {
			return -1;
		} break;
	}
}
void AETaskSetLabels(Task* task, char* label, char* command) {
	free(task->label);
	free(task->command);
	task->label = malloc(sizeof(char)*(strlen(label)+1));
	task->command = malloc(sizeof(char)*(strlen(command)+1));
	strcpy(task->label, label);
	strcpy(task->command, command);
}

// Recipe ==========================================================================================
Recipe* AERecipeCreate(long tn) {
	Recipe* recipe = (Recipe*)malloc(sizeof(Recipe));
	recipe->name = malloc(sizeof(char));
	recipe->name[0] = 0;
	recipe->tasks = (Task**)malloc(sizeof(Task*)*tn);
	recipe->tn = tn;
	recipe->ri = 0;
	recipe->pn = 0;
	recipe->mn = 0;
	recipe->params = 0;
	recipe->memory = 0;
	return recipe;
}
Recipe* AERecipeCreateClone(Recipe* recipe) {
	Recipe* clone = (Recipe*)malloc(sizeof(Recipe));
	clone->name = malloc(sizeof(char)*(strlen(recipe->name)+1));
	strcpy(clone->name, recipe->name);

	clone->tasks = (Task**)malloc(sizeof(Task*)*recipe->tn);
	clone->tn = recipe->tn;
	
	for (int i=0;i<clone->tn;i++)
		clone->tasks[i] = AETaskCreateClone(recipe->tasks[i]);
	
	clone->ri = recipe->ri;
	clone->pn = recipe->pn;
	clone->params = (mnimi*)malloc(sizeof(mnimi)*recipe->pn);

	for (int i=0;i<clone->pn;i++)
		clone->params[i] = recipe->params[i];
	
	clone->memory = recipe->memory ? AEMemoryCreateClone(recipe->memory) : 0;
	
	return clone;
}
void AERecipeRelease(Recipe* recipe) {
	if (recipe == 0) return;
	free(recipe->name);
	for (int i=0;i<recipe->tn;i++)
		AETaskRelease(recipe->tasks[i]);
	free(recipe->tasks);
	free(recipe->params);
	AEMemoryRelease(recipe->memory);
	free(recipe);
}
void AERecipeSetName(Recipe* recipe, char* name) {
	free(recipe->name);
	recipe->name = malloc(sizeof(char)*(strlen(name)+1));
	strcpy(recipe->name, name);
}
void AERecipeSetMemory(Recipe* recipe, Memory* memory) {
	recipe->memory = AEMemoryCreateClone(memory);
	int mi = 0;
	for (int i=0;i<recipe->pn;i++) {
		Slot* slot = &recipe->memory->slots[recipe->params[i]];
		slot->stacked = 1;
		slot->offset = mi;
		mi++;
	}
	for (int i=0;i<memory->sn;i++) {
		Slot* slot = &recipe->memory->slots[i];
		if (!slot->stacked && !slot->fixed && slot->loaded) {
			slot->stacked = 1;
			slot->offset = mi;
			mi++;
		}
	}
	recipe->mn = mi;
	for (int i=0;i<memory->sn;i++) {
		Slot* slot = &recipe->memory->slots[i];
		if (slot->stacked)
			slot->offset -= mi;
	}
}
void AERecipeSignature(Recipe* recipe, mnimi ri, byte pn) {
	recipe->ri = ri;
	recipe->pn = pn;
	recipe->params = (mnimi*)malloc(sizeof(mnimi)*recipe->pn);
}
byte AERecipeExecute(Recipe* recipe, Memory* memory) {
	struct timespec start, stop;
	long tp = 0;
	long n = 0;
	byte on = 0;
	while (tp < recipe->tn) {
		long go2 = AETaskExecute(recipe->tasks[tp], memory);
		tp = go2 == -1 ? tp+1 : go2;
		if (n++ == 100000) {
			n = 0;

			if (!on) {
				on = 1;
				clock_gettime(CLOCK_MONOTONIC, &start);
			}

			clock_gettime(CLOCK_MONOTONIC, &stop);

			if (stop.tv_sec != start.tv_sec && (stop.tv_sec != start.tv_sec+1 || stop.tv_nsec >= start.tv_nsec)) {
				return 0;
			}
		}
	}
	return 1;
}
void AERecipePrint(Recipe* recipe) {
	printf("[ Recipe ============================================= ]\n");
	printf("  pn: %d\n", recipe->pn);
	printf("  mn: %d\n", recipe->mn);
	printf("  Tasks ---------------------------------------------- ]\n");
	for (int i=0;i<recipe->tn;i++) {
		Task* task = recipe->tasks[i];
		printf("  %2d> %12s : %-32s\n", i, task->label, task->command);
	}
	printf("[ ==================================================== ]\n\n");
}

// Aegean ==========================================================================================
void startAegean() {
	AEPoolThreadInit();
}

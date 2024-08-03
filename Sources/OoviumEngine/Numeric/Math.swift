//
//  Math.swift
//  Oovium
//
//  Created by Joe Charlier on 11/29/16.
//  Copyright © 2016 Aepryus Software. All rights reserved.
//

import Aegean
import Foundation

public extension Morph {
	var def: Def {
		switch self {
			case MorphComplex, MorphCpxVar, MorphCpxCns, MorphCpxAdd, MorphCpxSub, MorphCpxMul, MorphCpxDiv, MorphCpxPow, MorphCpxSin, MorphCpxCos, MorphCpxTan, MorphCpxLn, MorphCpxExp, MorphCpxSqrt, MorphCpxRound, MorphCpxFloor:
				return ComplexDef.def
            case MorphVector, MorphVctVar, MorphVctCns, MorphVctAdd, MorphVctSub, MorphVctMulL, MorphVctMulR, MorphVctDiv, MorphVctCross, MorphVctNeg:
				return VectorDef.def
			case MorphStrVar, MorphStrCns, MorphStrAdd:
				return StringDef.def
			case MorphLmbVar, MorphLmbCns:
				return LambdaDef.def
			case MorphRcpVar:
				return RecipeDef.def
			default:
				return RealDef.def
		}
	}
}

@_cdecl("Oovium_objToString")
public func objToString(_ obj: Obj) -> UnsafeMutablePointer<Int8> { Def.format(obj: obj).toInt8() }

public final class Math {
	private static var morphs = [String:UInt32]()
	
	private static func registerMorph(key: String, morph: Morph) { morphs[key] = morph.rawValue }
	private static func registerOperator(token: Token, defs: [Def], morph: Morph) {
		var key = "\(token.tag);"
		defs.forEach { key += "\($0.key);" }
		registerMorph(key: key, morph: morph)
	}
	static func morph(key: String) throws -> UInt32 {
		guard let morph = morphs[key] else {
			print("key [\(key)] not found!")
			throw ParseError.general
		}
		return morph
	}
	
// Recipe ==========================================================================================
	private static func program(tasks: inout [UnsafeMutablePointer<Task>], tail: Tower, memory: UnsafeMutablePointer<Memory>, additional: Set<Tower>, completed: Set<Tower>, n: Int) -> Int {
		var n = n
		var completed = completed
		var progress: Bool
		
		var gates: [Tower] = []
		
		completed.formUnion(additional)
		
		repeat {
			progress = false
			
			for tower in additional {
				guard tower.attemptToFire(memory) else {continue}
				
				progress = true
				tasks.append(AETaskCreateClone(tower.task!))
				n += 1
				
				if tower.gateTo != nil {gates.append(tower)}
			}
			
			for gate in gates {
				let thenTowers: Set<Tower> = tail.stronglyLinked(override: gate.thenTo).subtracting(completed)
				let elseTowers: Set<Tower> = tail.stronglyLinked(override: gate.elseTo).subtracting(completed)
				
				guard thenTowers != elseTowers else { continue }
				
				progress = true
				
				let ifGotoIndex = n
				tasks.append(AETaskCreateIfGoto(0, 0))
				n += 1
				
				n = program(tasks: &tasks, tail: tail, memory: AEMemoryCreateClone(memory), additional: thenTowers, completed: completed, n: n)
                var ifGotoN = n+1
				
				let gotoIndex = n
				tasks.append(AETaskCreateGoto(0))
				n += 1
				let oldN = n
				n = program(tasks: &tasks, tail: tail, memory: AEMemoryCreateClone(memory), additional: elseTowers, completed: completed, n: n)
				if oldN != n {
					AETaskRelease(tasks[gotoIndex])
					tasks[gotoIndex] = AETaskCreateGoto(UInt8(n))
					AETaskSetLabels(tasks[gotoIndex], "".toInt8(), "GOTO \(n)".toInt8())
				} else {
					tasks.removeLast()
					n -= 1
                    ifGotoN -= 1
				}
                
                AETaskRelease(tasks[ifGotoIndex])
                tasks[ifGotoIndex] = AETaskCreateIfGoto(AEMemoryIndexForName(memory, gate.name.toInt8()), UInt8(ifGotoN))
                AETaskSetLabels(tasks[ifGotoIndex], "".toInt8(), "IF \(gate.name) == FALSE GOTO \(ifGotoN)".toInt8())
				
				memory.pointee.slots[Int(gate.gateTo!.index)].loaded = 1
				tasks.append(AETaskCreateClone(gate.gateTo!.task!))
				n += 1
			}
			gates.removeAll()
			
		} while (progress)
		
		return n
	}
	public static func compile(result: Tower, memory: UnsafeMutablePointer<Memory>) -> UnsafeMutablePointer<Recipe> {
		var tasks = [UnsafeMutablePointer<Task>]()
		
		_ = program(tasks: &tasks, tail: result, memory: memory, additional: result.stronglyLinked(), completed: Set<Tower>(), n: 0)
		
		let recipe = AERecipeCreate(tasks.count)!
		var i = 0
		for task in tasks {
			recipe.pointee.tasks[i] = task
			i += 1
		}
		
		return recipe
	}
	
// Start ===========================================================================================
	public static func start() {
		startAegean()
        Token.start()

		registerOperator(token: Token.add,				defs: [RealDef.def, RealDef.def],	morph: MorphAdd)
		registerOperator(token: Token.subtract,			defs: [RealDef.def, RealDef.def],	morph: MorphSub)
		registerOperator(token: Token.multiply,			defs: [RealDef.def, RealDef.def],	morph: MorphMul)
		registerOperator(token: Token.divide,			defs: [RealDef.def, RealDef.def],	morph: MorphDiv)
		registerOperator(token: Token.mod,				defs: [RealDef.def, RealDef.def],	morph: MorphMod)
		registerOperator(token: Token.power,			defs: [RealDef.def, RealDef.def],	morph: MorphPow)
		registerOperator(token: Token.equal,			defs: [RealDef.def, RealDef.def],	morph: MorphEqual)
		registerOperator(token: Token.notEqual,			defs: [RealDef.def, RealDef.def],	morph: MorphNotEqual)
		registerOperator(token: Token.less,				defs: [RealDef.def, RealDef.def],	morph: MorphLessThan)
		registerOperator(token: Token.lessOrEqual,		defs: [RealDef.def, RealDef.def],	morph: MorphLessThanOrEqual)
		registerOperator(token: Token.greater,			defs: [RealDef.def, RealDef.def],	morph: MorphGreaterThan)
		registerOperator(token: Token.greaterOrEqual,	defs: [RealDef.def, RealDef.def],	morph: MorphGreaterThanOrEqual)
		registerOperator(token: Token.and,				defs: [RealDef.def, RealDef.def],	morph: MorphAnd)
		registerOperator(token: Token.or,				defs: [RealDef.def, RealDef.def],	morph: MorphOr)
		
		registerOperator(token: Token.add,			defs: [ComplexDef.def, ComplexDef.def],	morph: MorphCpxAdd)
		registerOperator(token: Token.add,			defs: [RealDef.def, ComplexDef.def],	morph: MorphCpxAdd)
		registerOperator(token: Token.add,			defs: [ComplexDef.def, RealDef.def],	morph: MorphCpxAdd)
		registerOperator(token: Token.subtract,		defs: [ComplexDef.def, ComplexDef.def],	morph: MorphCpxSub)
		registerOperator(token: Token.subtract,		defs: [RealDef.def, ComplexDef.def],	morph: MorphCpxSub)
		registerOperator(token: Token.subtract,		defs: [ComplexDef.def, RealDef.def],	morph: MorphCpxSub)
		registerOperator(token: Token.multiply,		defs: [ComplexDef.def, ComplexDef.def],	morph: MorphCpxMul)
		registerOperator(token: Token.multiply,		defs: [RealDef.def, ComplexDef.def],	morph: MorphCpxMul)
		registerOperator(token: Token.multiply,		defs: [ComplexDef.def, RealDef.def],	morph: MorphCpxMul)
		registerOperator(token: Token.divide,		defs: [ComplexDef.def, ComplexDef.def],	morph: MorphCpxDiv)
		registerOperator(token: Token.divide,		defs: [RealDef.def, ComplexDef.def],	morph: MorphCpxDiv)
		registerOperator(token: Token.divide,		defs: [ComplexDef.def, RealDef.def],	morph: MorphCpxDiv)
		registerOperator(token: Token.power,		defs: [ComplexDef.def, ComplexDef.def],	morph: MorphCpxPow)
		registerOperator(token: Token.power,		defs: [RealDef.def, ComplexDef.def],	morph: MorphCpxPow)
		registerOperator(token: Token.power,		defs: [ComplexDef.def, RealDef.def],	morph: MorphCpxPow)
		registerOperator(token: Token.equal,		defs: [ComplexDef.def, ComplexDef.def],	morph: MorphCpxEqual)
		registerOperator(token: Token.equal,		defs: [RealDef.def, ComplexDef.def],	morph: MorphCpxEqual)
		registerOperator(token: Token.equal,		defs: [ComplexDef.def, RealDef.def],	morph: MorphCpxEqual)
		registerOperator(token: Token.notEqual,		defs: [ComplexDef.def, ComplexDef.def],	morph: MorphCpxNotEqual)
		registerOperator(token: Token.notEqual,		defs: [RealDef.def, ComplexDef.def],	morph: MorphCpxNotEqual)
		registerOperator(token: Token.notEqual,		defs: [ComplexDef.def, RealDef.def],	morph: MorphCpxNotEqual)
		
		registerOperator(token: Token.add,			defs: [VectorDef.def, VectorDef.def],	morph: MorphVctAdd)
		registerOperator(token: Token.subtract,		defs: [VectorDef.def, VectorDef.def],	morph: MorphVctSub)
		registerOperator(token: Token.multiply,		defs: [RealDef.def, VectorDef.def],		morph: MorphVctMulL)
		registerOperator(token: Token.multiply,		defs: [VectorDef.def, RealDef.def],		morph: MorphVctMulR)
		registerOperator(token: Token.multiply,		defs: [VectorDef.def, VectorDef.def],	morph: MorphVctCross)
        registerOperator(token: Token.divide,       defs: [VectorDef.def, RealDef.def],     morph: MorphVctDiv)
		registerOperator(token: Token.dot,			defs: [VectorDef.def, VectorDef.def],	morph: MorphVctDot)
		
		registerOperator(token: Token.add,			defs: [StringDef.def, StringDef.def],	morph: MorphStrAdd)
		registerOperator(token: Token.add,			defs: [RealDef.def, StringDef.def],		morph: MorphStrAdd)
		registerOperator(token: Token.add,			defs: [StringDef.def, RealDef.def],		morph: MorphStrAdd)
		registerOperator(token: Token.add,			defs: [ComplexDef.def, StringDef.def],	morph: MorphStrAdd)
		registerOperator(token: Token.add,			defs: [StringDef.def, ComplexDef.def],	morph: MorphStrAdd)
		registerOperator(token: Token.add,			defs: [VectorDef.def, StringDef.def],	morph: MorphStrAdd)
		registerOperator(token: Token.add,			defs: [StringDef.def, VectorDef.def],	morph: MorphStrAdd)
		registerOperator(token: Token.add,			defs: [RecipeDef.def, StringDef.def],	morph: MorphStrAdd)
		registerOperator(token: Token.add,			defs: [StringDef.def, RecipeDef.def],	morph: MorphStrAdd)

		registerMorph(key: "−;num;", morph: MorphNeg)
		registerMorph(key: "!;num;", morph: MorphNot)
		
		registerMorph(key: "abs;num;", morph: MorphAbs)
		registerMorph(key: "round;num;", morph: MorphRound)
		registerMorph(key: "floor;num;", morph: MorphFloor)
		registerMorph(key: "sqrt;num;", morph: MorphSqrt)
		registerMorph(key: "fac;num;", morph: MorphFac)

		registerMorph(key: "sin;num;", morph: MorphSin)
		registerMorph(key: "cos;num;", morph: MorphCos)
		registerMorph(key: "tan;num;", morph: MorphTan)
		registerMorph(key: "sec;num;", morph: MorphSec)
		registerMorph(key: "csc;num;", morph: MorphCsc)
		registerMorph(key: "cot;num;", morph: MorphCot)
		registerMorph(key: "asin;num;", morph: MorphAsin)
		registerMorph(key: "acos;num;", morph: MorphAcos)
		registerMorph(key: "atan;num;", morph: MorphAtan)
		registerMorph(key: "sinh;num;", morph: MorphSinh)
		registerMorph(key: "cosh;num;", morph: MorphCosh)
		registerMorph(key: "tanh;num;", morph: MorphTanh)
		registerMorph(key: "asinh;num;", morph: MorphAsinh)
		registerMorph(key: "acosh;num;", morph: MorphAcosh)
		registerMorph(key: "atanh;num;", morph: MorphAtanh)
		
		registerMorph(key: "ln;num;", morph: MorphLn)
		registerMorph(key: "log;num;", morph: MorphLog)
		registerMorph(key: "log2;num;", morph: MorphLog2)
		registerMorph(key: "exp;num;", morph: MorphExp)
		registerMorph(key: "ten;num;", morph: MorphTen)
		registerMorph(key: "two;num;", morph: MorphTwo)
		
		registerMorph(key: "if;num;num;num;", morph: MorphIf)
		registerMorph(key: "if;num;lmb;lmb;", morph: MorphLmbIf)
		registerMorph(key: "min;num;num;", morph: MorphMin)
		registerMorph(key: "max;num;num;", morph: MorphMax)
		registerMorph(key: "∑;num;num;rcp;", morph: MorphSum)
		registerMorph(key: "∑;num;num;lmb;", morph: MorphLmbSum)
		registerMorph(key: "random;num;", morph: MorphRandom)
		
		registerMorph(key: "var;num;", morph: MorphNumVar)
		registerMorph(key: "cns;num;", morph: MorphNumCns)
		
		registerMorph(key: "Complex;num;num;", morph: MorphComplex)
		registerMorph(key: "var;cpx;", morph: MorphCpxVar)
		registerMorph(key: "cns;cpx;", morph: MorphCpxCns)
		registerMorph(key: "sin;cpx;", morph: MorphCpxSin)
		registerMorph(key: "cos;cpx;", morph: MorphCpxCos)
		registerMorph(key: "tan;cpx;", morph: MorphCpxTan)
		registerMorph(key: "ln;cpx;", morph: MorphCpxLn)
		registerMorph(key: "exp;cpx;", morph: MorphCpxExp)
		registerMorph(key: "sqrt;cpx;", morph: MorphCpxSqrt)
		registerMorph(key: "abs;cpx;", morph: MorphCpxAbs)
		registerMorph(key: "round;cpx;", morph: MorphCpxRound)
		registerMorph(key: "floor;cpx;", morph: MorphCpxFloor)

		registerMorph(key: "Vector;num;num;num;", morph: MorphVector)
		registerMorph(key: "var;vct;", morph: MorphVctVar)
		registerMorph(key: "cns;vct;", morph: MorphVctCns)
		registerMorph(key: "−;vct;", morph: MorphVctNeg)
		
		registerMorph(key: "var;str;", morph: MorphStrVar)
		registerMorph(key: "cns;str;", morph: MorphStrCns)
		
		registerMorph(key: "var;lmb;", morph: MorphLmbVar)
		registerMorph(key: "cns;lmb;", morph: MorphLmbCns)
		
		registerMorph(key: "var;rcp;", morph: MorphRcpVar)
	}
}

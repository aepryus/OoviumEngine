//
//  Math.swift
//  Oovium
//
//  Created by Joe Charlier on 11/29/16.
//  Copyright © 2016 Aepryus Software. All rights reserved.
//

import Aegean
import Foundation

public enum Morph: Int {
	case add, sub, mul, div, mod, pow, equal, notEqual, lessThan, lessThanOrEqual, greaterThan, greaterThanOrEqual
	case not, and, or, neg, abs, round, floor, sqrt, fac, exp, ln, log, ten, two, log2, sin, cos, tan, asin, acos, atan
	case sec, csc, cot, sinh, cosh, tanh, asinh, acosh, atanh, `if`, min, max, sum, random, numVar, numCns
	case complex, cpxVar, cpxCns, cpxAdd, cpxSub, cpxMul, cpxDiv, cpxPow, cpxEqual, cpxNotEqual, cpxSin, cpxCos, cpxTan
	case cpxLn, cpxExp, cpxSqrt, cpxAbs, cpxRound, cpxFloor
	case vector, vctVar, vctCns, vctAdd, vctSub, vctMulL, vctMulR, vctDot, vctCross, vctNeg
	case strVar, strCns, strAdd, rcpVar, numVarForce, lmbVar, lmbCns, lmbIf, lmbSum
	case recipe
	
	var def: Def {
		switch self {
			case .complex, .cpxVar, .cpxCns, .cpxAdd, .cpxSub, .cpxMul, .cpxDiv, .cpxPow, .cpxSin, .cpxCos, .cpxTan, .cpxLn, .cpxExp, .cpxSqrt, .cpxRound, .cpxFloor:
				return ComplexDef.def
			case .vector, .vctVar, .vctCns, .vctAdd, .vctSub, .vctMulL, .vctMulR, .vctCross, .vctNeg:
				return VectorDef.def
			case .strVar, .strCns, .strAdd:
				return StringDef.def
			case .lmbVar, .lmbCns:
				return LambdaDef.def
			case .rcpVar:
				return RecipeDef.def
			default:
				return RealDef.def
		}
	}
}

@_cdecl("Oovium_objToString")
public func objToString(_ obj: Obj) -> UnsafeMutablePointer<Int8> { Def.format(obj: obj).toInt8() }

public final class Math {
	private static var morphs = [String:Int]()
	
	private static func registerMorph(key: String, morph: Morph) { morphs[key] = morph.rawValue }
	private static func registerOperator(token: Token, defs: [Def], morph: Morph) {
		var key = "\(token.tag);"
		defs.forEach { key += "\($0.key);" }
		registerMorph(key: key, morph: morph)
	}
	static func morph(key: String) throws -> Int {
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
	public static func compile(mech: Mech, memory: UnsafeMutablePointer<Memory>) -> UnsafeMutablePointer<Recipe> {
		let recipe = compile(result: mech.resultTower, memory: memory)
		AERecipeSetName(recipe, mech.name.toInt8())
		return recipe
	}
	public static func compile(tail: Tail, memory: UnsafeMutablePointer<Memory>) -> UnsafeMutablePointer<Recipe> {
		var tasks = [UnsafeMutablePointer<Task>]()
		var n: Int = 0
		var completed: Set<Tower> = Set<Tower>()
		
		var additional: Set<Tower> = tail.whileTower.stronglyLinked()
		n = program(tasks: &tasks, tail: tail.whileTower, memory: memory, additional: additional, completed: completed, n: n)
		completed.formUnion(additional)
		
		let ifGotoIndex = n
		tasks.append(AETaskCreateIfGoto(0, 0))
		n += 1
		
		for vertebra in tail.vertebras {
			additional = vertebra.chain.tower.stronglyLinked()
			n = program(tasks: &tasks, tail: vertebra.chain.tower, memory: memory, additional: additional, completed: completed, n: n)
			completed.formUnion(additional)
		}
		
		for vertebra in tail.vertebras {
			tasks.append(AETaskCreateAssign(
				AEMemoryIndexForName(memory, vertebra.chain.tower.name.toInt8()),
				AEMemoryIndexForName(memory, vertebra.tower.name.toInt8())
			));
			AETaskSetLabels(tasks[n], "".toInt8(), "\(vertebra.tower.name) = \(vertebra.chain.tower.name)".toInt8())
			n += 1
		}
		
		tasks.append(AETaskCreateGoto(UInt8(0)))
		AETaskSetLabels(tasks[n], "".toInt8(), "GOTO \(0)".toInt8())
		n += 1
		
		AETaskRelease(tasks[ifGotoIndex])
		tasks[ifGotoIndex] = AETaskCreateIfGoto(AEMemoryIndexForName(memory, tail.whileTower.name.toInt8()), UInt8(n))
		AETaskSetLabels(tasks[ifGotoIndex], "".toInt8(), "IF \(tail.whileTower.name) == FALSE GOTO \(n)".toInt8())
		
		additional = tail.resultTower.stronglyLinked()
		_ = program(tasks: &tasks, tail: tail.resultTower, memory: memory, additional: additional, completed: completed, n: n)
		
		let recipe = AERecipeCreate(tasks.count)!
		var i = 0
		for task in tasks {
			recipe.pointee.tasks[i] = task
			i += 1
		}
		AERecipeSetName(recipe, tail.name.toInt8())
		
		return recipe
	}
	
// Start ===========================================================================================
	public static func start() {
		startAegean()
        Token.start()

		registerOperator(token: Token.add,				defs: [RealDef.def, RealDef.def],	morph: .add)
		registerOperator(token: Token.subtract,			defs: [RealDef.def, RealDef.def],	morph: .sub)
		registerOperator(token: Token.multiply,			defs: [RealDef.def, RealDef.def],	morph: .mul)
		registerOperator(token: Token.divide,			defs: [RealDef.def, RealDef.def],	morph: .div)
		registerOperator(token: Token.mod,				defs: [RealDef.def, RealDef.def],	morph: .mod)
		registerOperator(token: Token.power,			defs: [RealDef.def, RealDef.def],	morph: .pow)
		registerOperator(token: Token.equal,			defs: [RealDef.def, RealDef.def],	morph: .equal)
		registerOperator(token: Token.notEqual,			defs: [RealDef.def, RealDef.def],	morph: .notEqual)
		registerOperator(token: Token.less,				defs: [RealDef.def, RealDef.def],	morph: .lessThan)
		registerOperator(token: Token.lessOrEqual,		defs: [RealDef.def, RealDef.def],	morph: .lessThanOrEqual)
		registerOperator(token: Token.greater,			defs: [RealDef.def, RealDef.def],	morph: .greaterThan)
		registerOperator(token: Token.greaterOrEqual,	defs: [RealDef.def, RealDef.def],	morph: .greaterThanOrEqual)
		registerOperator(token: Token.and,				defs: [RealDef.def, RealDef.def],	morph: .and)
		registerOperator(token: Token.or,				defs: [RealDef.def, RealDef.def],	morph: .or)
		
		registerOperator(token: Token.add,			defs: [ComplexDef.def, ComplexDef.def],	morph: .cpxAdd)
		registerOperator(token: Token.add,			defs: [RealDef.def, ComplexDef.def],	morph: .cpxAdd)
		registerOperator(token: Token.add,			defs: [ComplexDef.def, RealDef.def],	morph: .cpxAdd)
		registerOperator(token: Token.subtract,		defs: [ComplexDef.def, ComplexDef.def],	morph: .cpxSub)
		registerOperator(token: Token.subtract,		defs: [RealDef.def, ComplexDef.def],	morph: .cpxSub)
		registerOperator(token: Token.subtract,		defs: [ComplexDef.def, RealDef.def],	morph: .cpxSub)
		registerOperator(token: Token.multiply,		defs: [ComplexDef.def, ComplexDef.def],	morph: .cpxMul)
		registerOperator(token: Token.multiply,		defs: [RealDef.def, ComplexDef.def],	morph: .cpxMul)
		registerOperator(token: Token.multiply,		defs: [ComplexDef.def, RealDef.def],	morph: .cpxMul)
		registerOperator(token: Token.divide,		defs: [ComplexDef.def, ComplexDef.def],	morph: .cpxDiv)
		registerOperator(token: Token.divide,		defs: [RealDef.def, ComplexDef.def],	morph: .cpxDiv)
		registerOperator(token: Token.divide,		defs: [ComplexDef.def, RealDef.def],	morph: .cpxDiv)
		registerOperator(token: Token.power,		defs: [ComplexDef.def, ComplexDef.def],	morph: .cpxPow)
		registerOperator(token: Token.power,		defs: [RealDef.def, ComplexDef.def],	morph: .cpxPow)
		registerOperator(token: Token.power,		defs: [ComplexDef.def, RealDef.def],	morph: .cpxPow)
		registerOperator(token: Token.equal,		defs: [ComplexDef.def, ComplexDef.def],	morph: .cpxEqual)
		registerOperator(token: Token.equal,		defs: [RealDef.def, ComplexDef.def],	morph: .cpxEqual)
		registerOperator(token: Token.equal,		defs: [ComplexDef.def, RealDef.def],	morph: .cpxEqual)
		registerOperator(token: Token.notEqual,		defs: [ComplexDef.def, ComplexDef.def],	morph: .cpxNotEqual)
		registerOperator(token: Token.notEqual,		defs: [RealDef.def, ComplexDef.def],	morph: .cpxNotEqual)
		registerOperator(token: Token.notEqual,		defs: [ComplexDef.def, RealDef.def],	morph: .cpxNotEqual)
		
		registerOperator(token: Token.add,			defs: [VectorDef.def, VectorDef.def],	morph: .vctAdd)
		registerOperator(token: Token.subtract,		defs: [VectorDef.def, VectorDef.def],	morph: .vctSub)
		registerOperator(token: Token.multiply,		defs: [RealDef.def, VectorDef.def],		morph: .vctMulL)
		registerOperator(token: Token.multiply,		defs: [VectorDef.def, RealDef.def],		morph: .vctMulR)
		registerOperator(token: Token.multiply,		defs: [VectorDef.def, VectorDef.def],	morph: .vctCross)
		registerOperator(token: Token.dot,			defs: [VectorDef.def, VectorDef.def],	morph: .vctDot)
		
		registerOperator(token: Token.add,			defs: [StringDef.def, StringDef.def],	morph: .strAdd)
		registerOperator(token: Token.add,			defs: [RealDef.def, StringDef.def],		morph: .strAdd)
		registerOperator(token: Token.add,			defs: [StringDef.def, RealDef.def],		morph: .strAdd)
		registerOperator(token: Token.add,			defs: [ComplexDef.def, StringDef.def],	morph: .strAdd)
		registerOperator(token: Token.add,			defs: [StringDef.def, ComplexDef.def],	morph: .strAdd)
		registerOperator(token: Token.add,			defs: [VectorDef.def, StringDef.def],	morph: .strAdd)
		registerOperator(token: Token.add,			defs: [StringDef.def, VectorDef.def],	morph: .strAdd)
		registerOperator(token: Token.add,			defs: [RecipeDef.def, StringDef.def],	morph: .strAdd)
		registerOperator(token: Token.add,			defs: [StringDef.def, RecipeDef.def],	morph: .strAdd)

		registerMorph(key: "−;num;", morph: .neg)
		registerMorph(key: "!;num;", morph: .not)
		
		registerMorph(key: "abs;num;", morph: .abs)
		registerMorph(key: "round;num;", morph: .round)
		registerMorph(key: "floor;num;", morph: .floor)
		registerMorph(key: "sqrt;num;", morph: .sqrt)
		registerMorph(key: "fac;num;", morph: .fac)

		registerMorph(key: "sin;num;", morph: .sin)
		registerMorph(key: "cos;num;", morph: .cos)
		registerMorph(key: "tan;num;", morph: .tan)
		registerMorph(key: "sec;num;", morph: .sec)
		registerMorph(key: "csc;num;", morph: .csc)
		registerMorph(key: "cot;num;", morph: .cot)
		registerMorph(key: "asin;num;", morph: .asin)
		registerMorph(key: "acos;num;", morph: .acos)
		registerMorph(key: "atan;num;", morph: .atan)
		registerMorph(key: "sinh;num;", morph: .sinh)
		registerMorph(key: "cosh;num;", morph: .cosh)
		registerMorph(key: "tanh;num;", morph: .tanh)
		registerMorph(key: "asinh;num;", morph: .asinh)
		registerMorph(key: "acosh;num;", morph: .acosh)
		registerMorph(key: "atanh;num;", morph: .atanh)
		
		registerMorph(key: "ln;num;", morph: .ln)
		registerMorph(key: "log;num;", morph: .log)
		registerMorph(key: "log2;num;", morph: .log2)
		registerMorph(key: "exp;num;", morph: .exp)
		registerMorph(key: "ten;num;", morph: .ten)
		registerMorph(key: "two;num;", morph: .two)
		
		registerMorph(key: "if;num;num;num;", morph: .if)
		registerMorph(key: "if;num;lmb;lmb;", morph: .lmbIf)
		registerMorph(key: "min;num;num;", morph: .min)
		registerMorph(key: "max;num;num;", morph: .max)
		registerMorph(key: "∑;num;num;rcp;", morph: .sum)
		registerMorph(key: "∑;num;num;lmb;", morph: .lmbSum)
		registerMorph(key: "random;num;", morph: .random)
		
		registerMorph(key: "var;num;", morph: .numVar)
		registerMorph(key: "cns;num;", morph: .numCns)
		
		registerMorph(key: "Complex;num;num;", morph: .complex)
		registerMorph(key: "var;cpx;", morph: .cpxVar)
		registerMorph(key: "cns;cpx;", morph: .cpxCns)
		registerMorph(key: "sin;cpx;", morph: .cpxSin)
		registerMorph(key: "cos;cpx;", morph: .cpxCos)
		registerMorph(key: "tan;cpx;", morph: .cpxTan)
		registerMorph(key: "ln;cpx;", morph: .cpxLn)
		registerMorph(key: "exp;cpx;", morph: .cpxExp)
		registerMorph(key: "sqrt;cpx;", morph: .cpxSqrt)
		registerMorph(key: "abs;cpx;", morph: .cpxAbs)
		registerMorph(key: "round;cpx;", morph: .cpxRound)
		registerMorph(key: "floor;cpx;", morph: .cpxFloor)

		registerMorph(key: "Vector;num;num;num;", morph: .vector)
		registerMorph(key: "var;vct;", morph: .vctVar)
		registerMorph(key: "cns;vct;", morph: .vctCns)
		registerMorph(key: "−;vct;", morph: .vctNeg)
		
		registerMorph(key: "var;str;", morph: .strVar)
		registerMorph(key: "cns;str;", morph: .strCns)
		
		registerMorph(key: "var;lmb;", morph: .lmbVar)
		registerMorph(key: "cns;lmb;", morph: .lmbCns)
		
		registerMorph(key: "var;rcp;", morph: .rcpVar)
	}
}

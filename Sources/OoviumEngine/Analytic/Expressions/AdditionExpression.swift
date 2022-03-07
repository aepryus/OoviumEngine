//
//  AdditionExpression.swift
//  Oovium
//
//  Created by Joe Charlier on 5/7/21.
//  Copyright © 2021 Aepryus Software. All rights reserved.
//

import Foundation

class OperationExpression: Expression {
	enum Operation { case addition, multiplication }

	let operation: Operation
	let expressions: [Expression]

	init(operation: Operation, expressions: [Expression]) {
		self.operation = operation
		self.expressions = expressions
	}

// Expression ======================================================================================
	override func depends(on variable: Variable) -> Bool {
		for expression in expressions {
			if expression.depends(on: variable) { return true }
		}
		return false
	}

// Hashable ========================================================================================
	static func == (lhs: OperationExpression, rhs: OperationExpression) -> Bool {
		guard lhs.expressions.count == rhs.expressions.count else { return false }

		var bag: [Expression] = rhs.expressions

		lhs.expressions.forEach {
			for i: Int in 0..<bag.count {
				if $0 == bag[i] {
					bag.remove(at: i)
					break
				}
			}
		}

		return bag.count == 0
	}
	override func hash(into hasher: inout Hasher) {
		hasher.combine("\(operation)")
		expressions.forEach { $0.hash(into: &hasher) }
	}
}

class AdditionExpression: OperationExpression {

	init(expressions: [Expression]) {
		super.init(operation: .addition, expressions: expressions)
	}

// Expression ======================================================================================
	override func add(_ expression: Expression) -> Expression {
		return AdditionExpression(expressions: expressions + [expression])
	}
	override func attemptToRemove(variable: Variable) -> Actor? {
		let dependants: [Expression] = expressions.filter { $0.depends(on: variable) }
		guard dependants.count > 0 else { return nil }
		let inverse = dependants.map { $0.negate() }
		if inverse.count == 1 {
			return OperationActor(operation: operation, expression: inverse[0])
		} else {
			return OperationActor(operation: operation, expression: AdditionExpression(expressions: inverse))
		}
	}
	override func attemptToIsolate(variable: Variable) -> Actor? {
		let nondependants: [Expression] = expressions.filter { !$0.depends(on: variable) }
		guard nondependants.count > 0 else { return nil }
		let inverse = nondependants.map { operation == .addition ? $0.negate() : $0.invert() }
		if inverse.count == 1 {
			return OperationActor(operation: operation, expression: inverse[0])
		} else {
			return OperationActor(operation: operation, expression: AdditionExpression(expressions: inverse))
		}
	}
	override func reduce() -> Expression {
		var expressions: [Expression] = []
		self.expressions.forEach {
			if let expression = $0 as? AdditionExpression { expressions += expression.expressions }
			else { expressions.append($0) }
		}

		expressions = expressions.map { $0.reduce() }

		var abacus: [Expression:Value] = [:]

		expressions.forEach {
			let flavor = $0.flavor()
			if abacus[flavor] == nil {
				abacus[flavor] = $0.scalar()
			} else {
				abacus[flavor] = (abacus[flavor] as! Rational) + ($0.scalar() as! Rational)
			}
		}

		var results: [Expression] = []
		abacus.keys.forEach {
			guard let value: Rational = abacus[$0] as? Rational, value != Rational(0) else { return }
			if $0 is ValueExpression {
				results.append(ValueExpression(value: value))
			} else if value == Rational(1) {
				results.append($0)
			} else {
				results.append(MultiplicationExpression(expressions: [ValueExpression(value: value), $0]))
			}
		}
		if results.count == 1 { return results[0] }
		else { return AdditionExpression(expressions: results.sorted(by: { $0.order < $1.order })) }
	}
	override func scalar() -> Value {
		return Rational(1)
	}
	override func differentiate(with variable: Variable) -> Expression {
		return AdditionExpression(expressions: expressions.map { $0.differentiate(with: variable) }).reduce()
	}

// CustomStringConvertible =========================================================================
	override var description: String {
		var sb: String = ""
		for (i, expression) in expressions.enumerated() {
			if i < expressions.count-1 {
				sb += "\(expression) + "
			} else {
				sb += "\(expression)"
			}
		}
		return sb
	}
}


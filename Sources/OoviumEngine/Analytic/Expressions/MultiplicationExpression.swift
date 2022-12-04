//
//  MultiplicationExpression.swift
//  Oovium
//
//  Created by Joe Charlier on 5/7/21.
//  Copyright © 2021 Aepryus Software. All rights reserved.
//

import Foundation

class MultiplicationExpression: OperationExpression {

	init(expressions: [Expression]) {
		super.init(operation: .multiplication, expressions: expressions)
	}

	func multiply(rational: Rational) -> Expression {
		var rational: Rational = rational
		var others: [Expression] = []

		for expression in expressions {
			if let expression = expression as? ValueExpression, let value = expression.value as? Rational {
				rational *= value
			} else {
				others.append(expression)
			}
		}

		if others.count == 0 {
			return ValueExpression(value: rational)
		} else if rational == Rational(1) {
			if others.count == 1 { return others[0] }
			else { return MultiplicationExpression(expressions: others) }
		} else {
			return MultiplicationExpression(expressions: [ValueExpression(value: rational)] + others)
		}
	}
	func multiply(powerExpression: PowerExpression) -> Expression {
		var powerExpressions: [Expression] = [powerExpression.power]
		var others: [Expression] = []

		for expression in expressions {
			if let expression = expression as? PowerExpression, expression.expression == powerExpression.expression {
				powerExpressions.append(expression.power)
			} else if expression == powerExpression.expression {
				powerExpressions.append(ValueExpression(value: Rational(1)))
			} else {
				others.append(expression)
			}
		}

		let newPower = AdditionExpression(expressions: powerExpressions).reduce()

		if others.count == 0 {
			return PowerExpression(expression: powerExpression.expression, power: newPower)
		} else if let npe = newPower as? ValueExpression, let rational = npe.value as? Rational, rational == Rational(0) {
			return ValueExpression(value: Rational(1))
		} else if let npe = newPower as? ValueExpression, let rational = npe.value as? Rational, rational == Rational(1) {
			return powerExpression.expression
		} else {
			return MultiplicationExpression(expressions: others + [PowerExpression(expression: powerExpression.expression, power: newPower)])
		}
	}
	func multiply(variableExpression: VariableExpression) -> Expression {
		multiply(powerExpression: PowerExpression(expression: variableExpression, power: ValueExpression(value: Rational(1))))
	}

// Expression ======================================================================================
	override var order: Int {
		var min: Int = 0
		expressions.forEach { if $0.order < min { min = $0.order } }
		return min
	}
	override func attemptToRemove(variable: Variable) -> Actor? {
		let dependants: [Expression] = expressions.filter { $0.depends(on: variable) }
		guard dependants.count > 0 else { return nil }
		let inverse = dependants.map { $0.invert() }
		if inverse.count == 1 {
			return OperationActor(operation: operation, expression: inverse[0])
		} else {
			return OperationActor(operation: operation, expression: MultiplicationExpression(expressions: inverse))
		}
	}
	override func attemptToIsolate(variable: Variable) -> Actor? {
		let nondependants: [Expression] = expressions.filter { !$0.depends(on: variable) }
		guard nondependants.count > 0 else { return nil }
		let inverse = nondependants.map { operation == .addition ? $0.negate() : $0.invert() }
		if inverse.count == 1 {
			return OperationActor(operation: operation, expression: inverse[0])
		} else {
			return OperationActor(operation: operation, expression: MultiplicationExpression(expressions: inverse))
		}
	}
	override func reduce() -> Expression {
		let expressions: [Expression] = expressions.map { $0.reduce() }

		var reduced: Expression = ValueExpression(value: Rational(1))
		expressions.forEach { reduced = reduced * $0 }
		return reduced
	}
	override func flavor() -> Expression {
		let reduced = reduce()
		if let multiply = reduced as? MultiplicationExpression {
			let filtered = multiply.expressions.filter { !($0 is ValueExpression) }
			if filtered.count == 1 { return filtered[0] }
			else { return MultiplicationExpression(expressions: filtered) }
		} else {
			return reduced.flavor()
		}
	}
	override func scalar() -> Value {
		let reduced = reduce()
		if let multiply = reduced as? MultiplicationExpression {
			if let valueExpression: ValueExpression = multiply.expressions.first(where: { $0 is ValueExpression }) as? ValueExpression {
				return valueExpression.value
			} else { return Rational(1) }
		} else { return reduced.scalar() }
	}
	override func differentiate(with variable: Variable) -> Expression {
		return AdditionExpression(expressions: expressions.enumerated().map {
			var expressions = self.expressions
			expressions.remove(at: $0)
			return MultiplicationExpression(expressions: [$1.differentiate(with: variable)] + expressions)
		}).reduce()
	}

// CustomStringConvertible =========================================================================
	override var description: String {
		var sb: String = ""
		expressions.forEach {
			if $0 is AdditionExpression { sb += "(\($0))" }
			else { sb += "\($0)" }
		}
		return sb
	}
}

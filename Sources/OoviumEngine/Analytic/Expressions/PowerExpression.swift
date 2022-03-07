//
//  PowerExpression.swift
//  Oovium
//
//  Created by Joe Charlier on 5/7/21.
//  Copyright © 2021 Aepryus Software. All rights reserved.
//

import Foundation

class PowerExpression: Expression {
	let expression: Expression
	let power: Expression

	init(expression: Expression, power: Expression) {
		self.expression = expression
		self.power = power
	}

// Expression ======================================================================================
	override var order: Int {
		if let power = power as? ValueExpression, let rational = power.value as? Rational {
			return -Int(round(Double(rational.numerator)/Double(rational.denominator)))
		} else {
			return -2
		}
	}
	override func depends(on variable: Variable) -> Bool {
		return expression.depends(on: variable) || power.depends(on: variable)
	}
	override func reduce() -> Expression {
		let expression = expression.reduce()
		let power = power.reduce()
		if let power = power as? ValueExpression, let rational = power.value as? Rational, rational == Rational(1) {
			return expression
		} else { return PowerExpression(expression: expression, power: power) }
	}
	override func differentiate(with variable: Variable) -> Expression {
		guard depends(on: variable) else { return super.differentiate(with: variable) }

		if !power.depends(on: variable) {
			return MultiplicationExpression(expressions: [power, PowerExpression(expression: expression, power: power.add(ValueExpression(value: Rational(-1)))), expression.differentiate(with: variable)]).reduce()

		} else {
			return super.differentiate(with: variable)
		}
	}

// Hashable ========================================================================================
	static func == (lhs: PowerExpression, rhs: PowerExpression) -> Bool {
		return lhs.expression == rhs.expression && lhs.power == rhs.power
	}
	override func hash(into hasher: inout Hasher) {
		expression.hash(into: &hasher)
		power.hash(into: &hasher)
	}

// CustomStringConvertible =========================================================================
	override var description: String {
		var sb: String = ""
		if expression is AdditionExpression || expression is MultiplicationExpression {
			sb.append("(\(expression))")
		} else {
			sb.append("\(expression)")
		}
		if power is AdditionExpression  {
			sb.append("^(\(power))")
		} else {
			sb.append("^\(power)")
		}
		return sb
	}
}

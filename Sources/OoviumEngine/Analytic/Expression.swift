//
//  Expression.swift
//  Oovium
//
//  Created by Joe Charlier on 5/5/21.
//  Copyright © 2021 Aepryus Software. All rights reserved.
//

import Foundation

public class Expression: Hashable, CustomStringConvertible {
	func depends(on variable: Variable) -> Bool { false }
	func isolated(to variable: Variable) -> Bool { false }
	func attemptToRemove(variable: Variable) -> Actor? { nil }
	func attemptToIsolate(variable: Variable) -> Actor? { nil }
	func reduce() -> Expression { self }
	func flavor() -> Expression { self }
	func scalar() -> Value { Rational(1) }
	func differentiate(with variable: Variable) -> Expression { ValueExpression(value: Rational(0)) }
    
    func substitute(variable: String, with value: Value) -> Expression { self }

	var order: Int { 0 }

	func add(_ expression: Expression) -> Expression { AdditionExpression(expressions: [self, expression]) }
	func negate() -> Expression { MultiplicationExpression(expressions: [ValueExpression(value: Rational(-1)), self]) }
	func invert() -> Expression { PowerExpression(expression: self, power: ValueExpression(value: Rational(-1))) }

	static func * (lhs: Expression, rhs: Expression) -> Expression {
        // Rational ================================================================================
		if let lhs = lhs as? ValueExpression, let lV = lhs.value as? Rational, lV == Rational(1) {
			return rhs

		} else if let rhs = rhs as? ValueExpression, let rV = rhs.value as? Rational, rV == Rational(1) {
			return lhs

		} else if let lhs = lhs as? ValueExpression, let lV = lhs.value as? Rational, let rhs = rhs as? ValueExpression, let rV = rhs.value as? Rational {
			return ValueExpression(value: lV*rV)

		} else if let lhs = lhs as? ValueExpression, let lV = lhs.value as? Rational, let rhs = rhs as? MultiplicationExpression {
			return rhs.multiply(rational: lV)

		} else if let lhs = lhs as? MultiplicationExpression, let rhs = rhs as? ValueExpression, let rV = rhs.value as? Rational {
			return lhs.multiply(rational: rV)
            
        // Tensor ==================================================================================

        } else if let lhs = lhs as? ValueExpression, let lV = lhs.value as? Tensor, let rhs = rhs as? ValueExpression, let rV = rhs.value as? Tensor {
            return ValueExpression(value: lV*rV)

        } else if let lhs = lhs as? ValueExpression, let lV = lhs.value as? Tensor, let rhs = rhs as? MultiplicationExpression {
            return rhs.multiply(tensor: lV)

        } else if let lhs = lhs as? MultiplicationExpression, let rhs = rhs as? ValueExpression, let rV = rhs.value as? Tensor {
            return lhs.multiply(tensor: rV)

            
        // Other ===================================================================================
		} else if let lhs = lhs as? VariableExpression, let rhs = rhs as? MultiplicationExpression {
			return rhs.multiply(variableExpression: lhs)

		} else if let lhs = lhs as? MultiplicationExpression, let rhs = rhs as? VariableExpression {
			return lhs.multiply(variableExpression: rhs)

		} else if let lhs = lhs as? MultiplicationExpression, let rhs = rhs as? MultiplicationExpression {
			return MultiplicationExpression(expressions: lhs.expressions + rhs.expressions).reduce()

		} else if let lhs = lhs as? AdditionExpression {
			var expressions: [Expression] = []
			lhs.expressions.forEach { expressions.append($0 * rhs) }
			return AdditionExpression(expressions: expressions).reduce()

		} else if let rhs = rhs as? AdditionExpression {
			var expressions: [Expression] = []
			rhs.expressions.forEach { expressions.append(lhs * $0) }
			return AdditionExpression(expressions: expressions).reduce()

		} else if let lhs = lhs as? PowerExpression, let rhs = rhs as? PowerExpression, lhs.expression == rhs.expression {
			return PowerExpression(expression: lhs.expression, power: AdditionExpression(expressions: [lhs.power, rhs.power]).reduce()).reduce()

		} else if let lhs = lhs as? PowerExpression, lhs.expression == rhs {
			return PowerExpression(expression: lhs.expression, power: AdditionExpression(expressions: [lhs.power, ValueExpression(value: Rational(1))]).reduce()).reduce()

		} else if let rhs = rhs as? PowerExpression, rhs.expression == lhs {
			return PowerExpression(expression: rhs.expression, power: AdditionExpression(expressions: [ValueExpression(value: Rational(1)), rhs.power]).reduce()).reduce()

		} else if lhs == rhs {
			return PowerExpression(expression: lhs, power: ValueExpression(value: Rational(2))).reduce()

		} else {
			return MultiplicationExpression(expressions: [lhs, rhs])
		}
	}

// Hashable ========================================================================================
	public static func == (lhs: Expression, rhs: Expression) -> Bool {
		guard type(of: lhs) == type(of: rhs) else { return false }

		if lhs is ValueExpression { return (lhs as! ValueExpression) == (rhs as! ValueExpression) }
		if lhs is VariableExpression { return (lhs as! VariableExpression) == (rhs as! VariableExpression) }
		if lhs is FunctionExpression { return (lhs as! FunctionExpression) == (rhs as! FunctionExpression) }
		if lhs is AdditionExpression { return (lhs as! AdditionExpression) == (rhs as! AdditionExpression) }
		if lhs is MultiplicationExpression { return (lhs as! MultiplicationExpression) == (rhs as! MultiplicationExpression) }
		if lhs is PowerExpression { return (lhs as! PowerExpression) == (rhs as! PowerExpression) }

		fatalError()
	}
	public func hash(into hasher: inout Hasher) { }

// CustomStringConvertible =========================================================================
	public var description: String { "[IMPLEMENT ME]" }
}

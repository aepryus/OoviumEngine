//
//  Action.swift
//  Oovium
//
//  Created by Joe Charlier on 5/6/21.
//  Copyright © 2021 Aepryus Software. All rights reserved.
//

import Foundation

protocol Actor {
	func act(on expression: Expression) -> Expression
}

class OperationActor: Actor {
	let operation: OperationExpression.Operation
	let expression: Expression

	init(operation: OperationExpression.Operation, expression: Expression) {
		self.operation = operation
		self.expression = expression
	}

// Actor ===========================================================================================
	func act(on expression: Expression) -> Expression {
		var operands: [Expression] = []

		for expression in [self.expression, expression] {
			if let expression = expression as? OperationExpression, expression.operation == operation {
				operands += expression.expressions
			} else {
				operands += [expression]
			}
		}

		if operation == .addition {
			return AdditionExpression(expressions: operands).reduce()
		} else/* if operation == .multiplication*/ {
			return MultiplicationExpression(expressions: operands).reduce()
		}
	}
}

class FunctionActor: Actor {
	let function: Function

	init(function: Function) {
		self.function = function
	}

// Actor ===========================================================================================
	func act(on expression: Expression) -> Expression { FunctionExpression(function: function, expression: expression) }
}

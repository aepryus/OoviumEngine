//
//  FunctionExpression.swift
//  Oovium
//
//  Created by Joe Charlier on 5/7/21.
//  Copyright © 2021 Aepryus Software. All rights reserved.
//

import Foundation

class FunctionExpression: Expression {
	let function: Function
	let expression: Expression

	init(function: Function, expression: Expression) {
		self.function = function
		self.expression = expression
	}

// Expression ======================================================================================
	override var order: Int { -1 }
	override func depends(on variable: Variable) -> Bool { expression.depends(on: variable) }
	override func reduce() -> Expression {
		if let expression = expression as? FunctionExpression, function.isInverse(expression.function) {
			return expression.expression
		} else {
			return self
		}
	}
	override func scalar() -> Value { Rational(1) }

// Hashable ========================================================================================
	static func == (lhs: FunctionExpression, rhs: FunctionExpression) -> Bool { lhs.function == rhs.function && rhs.expression == lhs.expression }
	override func hash(into hasher: inout Hasher) {
		hasher.combine(function.name)
		expression.hash(into: &hasher)
	}

// CustomStringConvertible =========================================================================
	override var description: String { "\(function.name)(\(expression)" }
}

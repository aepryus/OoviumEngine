//
//  Function.swift
//  Oovium
//
//  Created by Joe Charlier on 5/5/21.
//  Copyright © 2021 Aepryus Software. All rights reserved.
//

import Foundation

class Function {
	let name: String
	let variables: [Variable]
	let expression: Expression
	let inverse: String

	init(name: String, variables: [Variable], expression: Expression, inverse: String) {
		self.name = name
		self.variables = variables
		self.expression = expression
		self.inverse = inverse
	}

	func analytic(values: [Value]) -> Expression {
		return Expression()
	}
	func numeric(values: [Value]) -> Value {
		return Value()
	}
	func differentiate() -> Function {
		return self
	}
	func integrate() -> Function {
		return self
	}
	func isInverse(_ function: Function) -> Bool {
		return inverse == function.name
	}
	static func == (lhs: Function, rhs: Function) -> Bool {
		return lhs.name == rhs.name
	}
}

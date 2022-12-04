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

	func analytic(values: [Value]) -> Expression { Expression() }
	func numeric(values: [Value]) -> Value { Value() }
	func differentiate() -> Function { self }
	func integrate() -> Function { self }
	func isInverse(_ function: Function) -> Bool { inverse == function.name }
	static func == (lhs: Function, rhs: Function) -> Bool { lhs.name == rhs.name }
}

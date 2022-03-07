//
//  VariableExpression.swift
//  Oovium
//
//  Created by Joe Charlier on 5/7/21.
//  Copyright © 2021 Aepryus Software. All rights reserved.
//

import Foundation

class VariableExpression: Expression {
	let variable: Variable

	init(variable: Variable) {
		self.variable = variable
	}

// Expression ======================================================================================
	override var order: Int { return -1 }
	override func depends(on variable: Variable) -> Bool {
		return variable == self.variable
	}
	override func isolated(to variable: Variable) -> Bool {
		return self.variable == variable
	}
	override func scalar() -> Value {
		return Rational(1)
	}
	override func differentiate(with variable: Variable) -> Expression {
		if variable == self.variable {
			return ValueExpression(value: Rational(1))
		} else {
			return ValueExpression(value: Rational(0))
		}
	}

// Hashable ========================================================================================
	static func == (lhs: VariableExpression, rhs: VariableExpression) -> Bool {
		return lhs.variable == rhs.variable
	}
	override func hash(into hasher: inout Hasher) {
		hasher.combine(variable.name)
	}

// CustomStringConvertible =========================================================================
	override var description: String {
		return variable.name
	}
}

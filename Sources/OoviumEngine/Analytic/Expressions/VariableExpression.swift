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
	override var order: Int { -1 }
	override func depends(on variable: Variable) -> Bool { variable == self.variable }
	override func isolated(to variable: Variable) -> Bool { self.variable == variable }
	override func scalar() -> Value { Rational(1) }
	override func differentiate(with variable: Variable) -> Expression {
		if variable == self.variable {
			return ValueExpression(value: Rational(1))
		} else {
			return ValueExpression(value: Rational(0))
		}
	}
    
    override func substitute(variable: String, with value: Value) -> Expression {
        if variable == self.variable.name { return ValueExpression(value: value) }
        return self
    }

// Hashable ========================================================================================
	static func == (lhs: VariableExpression, rhs: VariableExpression) -> Bool { lhs.variable == rhs.variable }
	override func hash(into hasher: inout Hasher) {
		hasher.combine(variable.name)
	}

// CustomStringConvertible =========================================================================
	override var description: String { variable.name }
}

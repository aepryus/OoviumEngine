//
//  ValueExpression.swift
//  Oovium
//
//  Created by Joe Charlier on 5/7/21.
//  Copyright © 2021 Aepryus Software. All rights reserved.
//

import Foundation

class ValueExpression: Expression {
	let value: Value

	init(value: Value) {
		self.value = value
	}

// Expression ======================================================================================
	override func negate() -> Expression {
		if let a: Rational = value as? Rational {
			return ValueExpression(value: -a)
		} else { return self }
	}
	override func invert() -> Expression {
		if let a: Rational = value as? Rational {
			return ValueExpression(value: 1/a)
		} else { return self }
	}
	override func flavor() -> Expression { ValueExpression(value: Rational(1)) }
	override func scalar() -> Value { value }

// Hashable ========================================================================================
	static func == (lhs: ValueExpression, rhs: ValueExpression) -> Bool {
		if let a = lhs.value as? Rational, let b = rhs.value as? Rational {
			return a == b
		} else { return false }
	}
	override func hash(into hasher: inout Hasher) {
		hasher.combine("\(value)")
	}

// CustomStringConvertible =========================================================================
	override var description: String { "\(value)" }
}

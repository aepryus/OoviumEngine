//
//  Value.swift
//  Oovium
//
//  Created by Joe Charlier on 5/5/21.
//  Copyright © 2021 Aepryus Software. All rights reserved.
//

import Foundation

class Value {
}

class Rational: Value, CustomStringConvertible {
	let numerator: Int
	let denominator: Int

	init(_ numerator: Int, _ denominator: Int = 1) {
		self.numerator = numerator
		self.denominator = denominator
	}

	func reduced() -> Rational {
		guard numerator % denominator != 0 else { return Rational(numerator/denominator) }
		guard denominator % numerator != 0 else { return Rational(1, denominator/numerator) }

		var numerator: Int = abs(self.numerator)
		var denominator: Int = abs(self.denominator)
		let negative: Int = (self.numerator < 0) == (self.denominator < 0) ? 1 : -1

		var p: Int = 2

		while p*p < min(numerator, denominator) {
			if numerator % p == 0 && denominator % p == 0 {
				numerator /= p
				denominator /= p
			} else {
				p += 1
			}
		}

		return Rational(negative * numerator, denominator)
	}

	static prefix func - (a: Rational) -> Rational {
		return Rational(-a.numerator, a.denominator)
	}
	static func + (_ a: Rational, _ b: Rational) -> Rational {
		return Rational(a.numerator*b.denominator + b.numerator*a.denominator, a.denominator*b.denominator).reduced()
	}
	static func * (_ a: Rational, _ b: Rational) -> Rational {
		return Rational(a.numerator*b.numerator, a.denominator*b.denominator).reduced()
	}
	static func *= (a: inout Rational, b: Rational) {
		a = Rational(a.numerator*b.numerator, a.denominator*b.denominator).reduced()
	}
	static func / (_ a: Int, _ b: Rational) -> Rational {
		return Rational(a*b.denominator, b.numerator)
	}
	static func == (_ a: Rational, _ b: Rational) -> Bool {
		let aR = a.reduced()
		let bR = b.reduced()
		return aR.numerator == bR.numerator && aR.denominator == bR.denominator
	}
	static func != (_ a: Rational, _ b: Rational) -> Bool {
		return !(a == b)
	}

// CustomStringConvertable =========================================================================
	var description: String {
		if denominator == 1 { return "\(numerator)" }
		else { return "\(numerator)/\(denominator)" }
	}
}

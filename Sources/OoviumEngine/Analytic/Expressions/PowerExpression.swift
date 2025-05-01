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
        
        if let power = power as? ValueExpression,
           let pRat = power.value as? Rational,
           let expression = expression as? ValueExpression,
           let eRat = expression.value as? Rational {
            
            let numD: Double = pow(eRat.numeric, abs(pRat.numeric))
            let numI: Int = Int(numD)
            
            if numD == Double(numI) {
                if pRat.numeric > 0 { return ValueExpression(value: Rational(numI)) }
                else { return ValueExpression(value: Rational(1, numI)) }
            }
        }

        if let power = power as? ValueExpression, let rational: Rational = power.value as? Rational, rational == Rational(1) {
            return expression
        } else if let power = power as? ValueExpression,
                  let rational: Rational = power.value as? Rational,
                  rational == Rational(-1),
                  let expression: ValueExpression = expression as? ValueExpression,
                  let value: Rational = expression.value as? Rational {
            return ValueExpression(value: Rational(value.denominator, value.numerator))
        } else if let power = power as? ValueExpression,
                  let expression = expression as? ValueExpression,
                  let powRat: Rational = power.value as? Rational,
                  let expRat: Rational = expression.value as? Rational,
                  powRat.denominator == 1 {
            
            let p: Int = abs(powRat.numerator)
            let rational: Rational
            if powRat.numerator > 0 {
                rational = Rational(AnainMath.pow(expRat.numerator, p), AnainMath.pow(expRat.denominator, p))
            } else {
                rational = Rational(AnainMath.pow(expRat.denominator, p), AnainMath.pow(expRat.numerator, p))
            }
            return ValueExpression(value: rational)
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
    
    override func substitute(variable: String, with value: Value) -> Expression {
        PowerExpression(
            expression: expression.substitute(variable: variable, with: value),
            power: power.substitute(variable: variable, with: value)
        )
    }

// Hashable ========================================================================================
	static func == (lhs: PowerExpression, rhs: PowerExpression) -> Bool { lhs.expression == rhs.expression && lhs.power == rhs.power }
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

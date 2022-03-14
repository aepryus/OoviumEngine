//
//  AnalyticTests.swift
//  OoviumEngineTests
//
//  Created by Joe Charlier on 5/5/21.
//  Copyright © 2021 Aepryus Software. All rights reserved.
//

@testable import OoviumEngine
import XCTest

class AnalyticTests: XCTestCase {

	func test_Rational() {
		let oneHalf = Rational(1, 2)
		let twoThirds = Rational(2, 3)

		let answer = oneHalf + twoThirds
		print("\(oneHalf) + \(twoThirds) = \(answer)")
		XCTAssert(answer == Rational(7, 6))

		let fraction = Rational(3013*8*9*7, 893*8*9*7)
		print("\(fraction) = \(fraction.reduced())")
		XCTAssert(fraction.reduced() == Rational(3013, 893))

		let f2 = Rational(21, 7)
		print("\(f2) = \(f2.reduced())")
		XCTAssert(f2.reduced() == Rational(3))

		let f3 = Rational(-63, 21)
		print("\(f3) = \(f3.reduced())")
		XCTAssert(f3.reduced() == Rational(-3))

		let f4 = twoThirds * oneHalf
		print("\(twoThirds) * \(oneHalf) = \(f4)")
		XCTAssert(f4 == Rational(1, 3))
	}
	func test_Algebra() {
		let x = Variable(name: "x")
		let threeX = MultiplicationExpression(expressions: [ValueExpression(value: Rational(3)), VariableExpression(variable: x)])
		let threeXplusSeven = AdditionExpression(expressions: [threeX, ValueExpression(value: Rational(7))])

		let equation = Equation(left: threeXplusSeven, right: ValueExpression(value: Rational(31)))

		let xEquals = equation.solve(for: x)

		if let valueExpression = xEquals as? ValueExpression, let rational = valueExpression.value as? Rational {
			XCTAssert(rational == Rational(8))
		} else {
			XCTAssert(false)
		}
	}
	func test_Algebra2() {
		let x = Variable(name: "x")
		let xPlusTwo = AdditionExpression(expressions: [VariableExpression(variable: x), ValueExpression(value: Rational(2))])
		let threeXPlusTwo = MultiplicationExpression(expressions: [ValueExpression(value: Rational(3)), xPlusTwo])
		let threeXPlusTwoPlusOne = AdditionExpression(expressions: [threeXPlusTwo, ValueExpression(value: Rational(1))])

		let equation = Equation(left: threeXPlusTwoPlusOne, right: ValueExpression(value: Rational(31)))

		let xEquals = equation.solve(for: x)

		if let valueExpression = xEquals as? ValueExpression, let rational = valueExpression.value as? Rational {
			XCTAssert(rational == Rational(8))
		} else {
			XCTAssert(false)
		}
	}
	func test_Multiply() {
		let a = ValueExpression(value: Rational(3))
		let b = ValueExpression(value: Rational(4))
		let c: ValueExpression = MultiplicationExpression(expressions: [a, b]).reduce() as! ValueExpression
		XCTAssert(c.value as! Rational == Rational(12))
	}
	func test_Multiply2() {
		let a = ValueExpression(value: Rational(3))
		let b = VariableExpression(variable: Variable(name: "x"))
		let c = ValueExpression(value: Rational(4))
		let d = MultiplicationExpression(expressions: [a, b, c]).reduce()
		XCTAssert("\(d)" == "12x")
	}
	func test_Multiply3() {
		let a = ValueExpression(value: Rational(3))
		let b = VariableExpression(variable: Variable(name: "x"))
		let c = VariableExpression(variable: Variable(name: "x"))
		let d = MultiplicationExpression(expressions: [a, b, c]).reduce()
		XCTAssert("\(d)" == "3x^2")
	}
	func test_Multiply4() {
		let a = ValueExpression(value: Rational(3))
		let b = VariableExpression(variable: Variable(name: "x"))
		let c = ValueExpression(value: Rational(4))
		let d = ValueExpression(value: Rational(5))
		let e = VariableExpression(variable: Variable(name: "x"))
		let f = ValueExpression(value: Rational(12))
		let g = MultiplicationExpression(expressions: [a, b])
		let h = AdditionExpression(expressions: [g, c])
		let i = MultiplicationExpression(expressions: [d, e])
		let j = AdditionExpression(expressions: [i, f])
		let k = MultiplicationExpression(expressions: [h, j]).reduce()
		XCTAssert("\(k)" == "15x^2 + 56x + 48")
	}
	func test_Algebra3() {
		let x = Variable(name: "x")
		let xPlusSeven = AdditionExpression(expressions: [VariableExpression(variable: x), ValueExpression(value: Rational(2))])
		let twoX = MultiplicationExpression(expressions: [ValueExpression(value: Rational(2)), VariableExpression(variable: x)])
		let twoXPlusThree = AdditionExpression(expressions: [twoX, ValueExpression(value: Rational(3))])
		let fiveXPlusSeven = MultiplicationExpression(expressions: [ValueExpression(value: Rational(5)), xPlusSeven])
		let threeTimesTwoXPlusThree = MultiplicationExpression(expressions: [ValueExpression(value: Rational(3)), twoXPlusThree])

		let equation = Equation(left: fiveXPlusSeven, right: threeTimesTwoXPlusThree)

		let xEquals = equation.solve(for: x)

		if let valueExpression = xEquals as? ValueExpression, let rational = valueExpression.value as? Rational {
			XCTAssert(rational == Rational(1))
		} else {
			XCTAssert(false)
		}
	}
	func test_Differentiate1() {
		let x = Variable(name: "x")
		let threeXSquared = MultiplicationExpression(expressions: [ValueExpression(value: Rational(3)), PowerExpression(expression: VariableExpression(variable: x), power: ValueExpression(value: Rational(2)))])
		let answer = threeXSquared.differentiate(with: x)
		XCTAssert("\(answer)" == "6x")
	}
	func test_Differentiate2() {
		let x = Variable(name: "x")
		let threeXSquared = MultiplicationExpression(expressions: [ValueExpression(value: Rational(3)), PowerExpression(expression: VariableExpression(variable: x), power: ValueExpression(value: Rational(2)))])
		let answer = threeXSquared.differentiate(with: x)
		print("############################     [ \(answer) ]")
		XCTAssert("\(answer)" == "6x")
	}
}

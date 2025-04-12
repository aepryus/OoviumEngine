//
//  AnalyticTests.swift
//  OoviumEngineTests
//
//  Created by Joe Charlier on 5/5/21.
//  Copyright © 2021 Aepryus Software. All rights reserved.
//

import Acheron
@testable import OoviumEngine
import XCTest

typealias Expression = OoviumEngine.Expression

class AnalyticTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        Math.start()
        Loom.namespaces = ["OoviumEngine"]
    }

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
    
    func test_Anain() {
        var anain: Anain = Anain(natural: "3")
        var expression: Expression? = anain.calculate()
        if let expression { print("############################     [ \(expression) ]") }
        else { print("Oops") }
        XCTAssert("\(expression!)" == "3")
        
        anain = Anain(natural: "3.7")
        expression = anain.calculate()
        if let expression { print("############################     [ \(expression) ]") }
        else { print("Oops") }
        XCTAssert("\(expression!)" == "37/10")
        
        XCTAssert(AnainMath.pow(8,3) == 8*8*8)
        XCTAssert(AnainMath.pow(7,3) == 7*7*7)
        XCTAssert(AnainMath.pow(7,5) == 7*7*7*7*7)
        XCTAssert(AnainMath.pow(2,8) == 2*2*2*2*2*2*2*2)
        XCTAssert(AnainMath.pow(11,4) == 11*11*11*11)
        
        anain = Anain(natural: "1/3")
        expression = anain.calculate()!.reduce()
        if let expression { print("############################     [ \(expression) ]") }
        else { print("Oops") }
        XCTAssert("\(expression!)" == "1/3")
        
        anain = Anain(natural: "2/3*1/2")
        expression = anain.calculate()!.reduce()
        if let expression { print("############################     [ \(expression) ]") }
        else { print("Oops") }
        XCTAssert("\(expression!)" == "1/3")

        anain = Anain(natural: "1/48*3+1/48")
        expression = anain.calculate()!.reduce()
        if let expression { print("############################     [ \(expression) ]") }
        else { print("Oops") }
        XCTAssert("\(expression!)" == "1/12")
        
        anain = Anain(natural: "1/48*5-1/48")
        expression = anain.calculate()!.reduce()
        if let expression { print("############################     [ \(expression) ]") }
        else { print("Oops") }
        XCTAssert("\(expression!)" == "1/12")
        
        anain = Anain(natural: "(1+2)/12+(3+4)/(3+5)")
        expression = anain.calculate()!.reduce()
        if let expression { print("############################     [ \(expression) ]") }
        else { print("Oops") }
        XCTAssert("\(expression!)" == "9/8")

    }
    
    func test_Tensors() {
        let x0: Expression = ValueExpression(value: Rational(3))
        let y0: Expression = ValueExpression(value: Rational(4))
        let vN: Tensor = Tensor(dimensions: 2, rank: 1, components: [x0, y0], isCovariant: [false])
        
        let x: Expression = VariableExpression(variable: Variable(name: "x"))
        let y: Expression = VariableExpression(variable: Variable(name: "y"))
        
        let q1: Expression = PowerExpression(expression: x, power: ValueExpression(value: Rational(2)))
        let q2: Expression = PowerExpression(expression: y, power: ValueExpression(value: Rational(2)))
        let q3: Expression = AdditionExpression(expressions: [q1, q2])
        let q4: Expression = PowerExpression(expression: q3, power: ValueExpression(value: Rational(1, 2)))
        
        let r: Expression = q4
        let Q: Expression = Anain(natural: "atan(y/x)").calculate()!
        
        print("r = \(r)")
        
        XCTAssert("\(r)" == "(x^2 + y^2)^1/2")

        print("Q = \(Q)")
        
        XCTAssert("\(Q)" == "atan(yx^-1)")
        
        let dQ: Expression = Q.differentiate(with: Variable(name: "x")).reduce()
        print("dQ = \(dQ)")
        
        XCTAssert("\(dQ)" == "(x^-1y^2x^-1 + 1)^-1-1x^-2y")
        
        let Q1: Expression = Anain(natural: "y/x").calculate()!
        let dQ1: Expression = Q1.differentiate(with: Variable(name: "x")).reduce()
        print("dQ1 = \(dQ1)")
        
        XCTAssert("\(dQ1)" == "-1x^-2y")

        let T: Tensor = Tensor(dimensions: 2, rank: 1, components: [r, Q], isCovariant: [false])
        
        print("T = \(T)")
        
        XCTAssert("\(T)" == "[(x^2 + y^2)^1/2, atan(yx^-1)]")

        let J: Expression = T.calculateJacobian(variables: ["x", "y"])
        
        print("J = \(J)")
        
//        XCTAssert("\(J)" == "[[(x^2 + y^2)^-1/2x, (x^2 + y^2)^-1/2y],\n [(x^-1y^2x^-1 + 1)^-1-1x^-2y, (x^-1y^2x^-1 + 1)^-1x^-1]]")
        
        guard let exp = J as? ValueExpression, let JT = exp.value as? Tensor else { return }
        
        let JN = ValueExpression(value: JT.substitute(vN))
        print("JN = \(JN)")
        
        XCTAssert("\(JN)" == "[[3/5, 4/5],\n [-4/25, 9/75]]")
        
        let JM = MultiplicationExpression(expressions: [JN, ValueExpression(value: vN)]).reduce()
        print("JM = \(JM)")
        
        XCTAssert("\(JM)" == "[5, 0]")
        
        let TM = ValueExpression(value: T.substitute(vN))
        print("TM = \(TM)")
        
        XCTAssert("\(TM)" == "[5, atan(4/3)]")

        let C = Anain(natural: "x^2+y^2").calculate()!
        
        print("C = \(C)")
        
        XCTAssert("\(C)" == "x^2 + y^2")

        let D = C.reduce()
        
        print("D = \(D)")
        
        XCTAssert("\(D)" == "x^2 + y^2" || "\(D)" == "y^2 + x^2")
        
        let A = Anain(natural: "(x^2+y^2)^(1/2)").calculate()!.reduce()
        
        print("A = \(A)")
        
        XCTAssert("\(A)" == "(x^2 + y^2)^1/2" || "\(A)" == "(y^2 + x^2)^1/2")
        
        let B = A.differentiate(with: Variable(name: "x"))
        
        print("B = \(B)")
        
        XCTAssert("\(B)" == "(x^2 + y^2)^-1/2x" || "\(B)" == "(y^2 + x^2)^-1/2x")
        
        let G = Anain(natural: "0").calculate()!.reduce()
        print("G = \(G)")
        
        XCTAssert("\(G)" == "0")
    }
}

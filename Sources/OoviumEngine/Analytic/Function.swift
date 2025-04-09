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
	let inverse: String

	init(name: String, inverse: String) {
		self.name = name
		self.inverse = inverse
	}

	func analytic(values: [Value]) -> Expression { Expression() }
	func numeric(values: [Value]) -> Value { Value() }
	func differentiate(argument: Expression) -> Expression { Expression() }
	func integrate(argument: Expression) -> Expression { Expression() }
	func isInverse(_ function: Function) -> Bool { inverse == function.name }
	static func == (lhs: Function, rhs: Function) -> Bool { lhs.name == rhs.name }
    
    static let sine = SineFunction()
    static let cosine = CosineFunction()
    static let tangent = TangentFunction()
    static let arcSine = ArcSineFunction()
    static let arcCosine = ArcCosineFunction()
    static let arcTangent = ArcTangentFunction()
    static let exponential = ExponentialFunction()
    static let logarithm = LogarithmFunction()
}

class DefinedFunction: Function {
    let variables: [Variable]
    let expression: Expression
    
    init(name: String, variables: [Variable], expression: Expression) {
        self.variables = variables
        self.expression = expression
        super.init(name: name, inverse: "")
    }
}

class SineFunction: Function {
    init() { super.init(name: "sin", inverse: "asin") }
    
// Function ========================================================================================
    override func differentiate(argument: Expression) -> Expression {
        FunctionExpression(function: .cosine, expression: argument)
    }
    override func integrate(argument: Expression) -> Expression {
        MultiplicationExpression(expressions: [
            FunctionExpression(function: .cosine, expression: argument),
            ValueExpression(value: Rational(-1))
        ])
    }
}

class CosineFunction: Function {
    init() { super.init(name: "cos", inverse: "acos") }
    
// Function ========================================================================================
    override func differentiate(argument: Expression) -> Expression {
        MultiplicationExpression(expressions: [
            FunctionExpression(function: .sine, expression: argument),
            ValueExpression(value: Rational(-1))
        ])
    }
    override func integrate(argument: Expression) -> Expression {
        FunctionExpression(function: .sine, expression: argument)
    }
}

class TangentFunction: Function {
    init() { super.init(name: "tan", inverse: "atan") }
    
// Function ========================================================================================
    override func differentiate(argument: Expression) -> Expression {
        PowerExpression(
            expression: FunctionExpression(function: .cosine, expression: argument),
            power: ValueExpression(value: Rational(-2))
        )
    }
    
    override func integrate(argument: Expression) -> Expression {
        MultiplicationExpression(expressions: [
            FunctionExpression(function: .logarithm, expression:
                FunctionExpression(function: .cosine, expression: argument)),
            ValueExpression(value: Rational(-1))
        ])
    }
}

class ArcSineFunction: Function {
    init() { super.init(name: "asin", inverse: "sin") }
    
// Function ========================================================================================
    override func differentiate(argument: Expression) -> Expression {
        PowerExpression(
            expression: AdditionExpression(expressions: [
                ValueExpression(value: Rational(1)),
                MultiplicationExpression(expressions: [
                    argument, argument, ValueExpression(value: Rational(-1))
                ])
            ]),
            power: ValueExpression(value: Rational(-1, 2))
        )
    }
    
    override func integrate(argument: Expression) -> Expression {
        AdditionExpression(expressions: [
            MultiplicationExpression(expressions: [
                argument, FunctionExpression(function: .arcSine, expression: argument)
            ]),
            MultiplicationExpression(expressions: [
                PowerExpression(
                    expression: AdditionExpression(expressions: [
                        ValueExpression(value: Rational(1)),
                        MultiplicationExpression(expressions: [
                            argument, argument, ValueExpression(value: Rational(-1))
                        ])
                    ]),
                    power: ValueExpression(value: Rational(1, 2))
                ),
                ValueExpression(value: Rational(-1))
            ])
        ])
    }
}

class ArcCosineFunction: Function {
    init() { super.init(name: "acos", inverse: "cos") }
    
// Function ========================================================================================
    override func differentiate(argument: Expression) -> Expression {
        MultiplicationExpression(expressions: [
            PowerExpression(
                expression: AdditionExpression(expressions: [
                    ValueExpression(value: Rational(1)),
                    MultiplicationExpression(expressions: [
                        argument, argument, ValueExpression(value: Rational(-1))
                    ])
                ]),
                power: ValueExpression(value: Rational(-1, 2))
            ),
            ValueExpression(value: Rational(-1))
        ])
    }
    
    override func integrate(argument: Expression) -> Expression {
        AdditionExpression(expressions: [
            MultiplicationExpression(expressions: [
                argument, FunctionExpression(function: .arcCosine, expression: argument)
            ]),
            PowerExpression(
                expression: AdditionExpression(expressions: [
                    ValueExpression(value: Rational(1)),
                    MultiplicationExpression(expressions: [
                        argument, argument, ValueExpression(value: Rational(-1))
                    ])
                ]),
                power: ValueExpression(value: Rational(1, 2))
            )
        ])
    }
}

class ArcTangentFunction: Function {
    init() { super.init(name: "atan", inverse: "tan") }
    
// Function ========================================================================================
    override func differentiate(argument: Expression) -> Expression {
        PowerExpression(
            expression: AdditionExpression(expressions: [
                ValueExpression(value: Rational(1)),
                MultiplicationExpression(expressions: [argument, argument])
            ]),
            power: ValueExpression(value: Rational(-1))
        )
    }    
    override func integrate(argument: Expression) -> Expression {
        AdditionExpression(expressions: [
            MultiplicationExpression(expressions: [
                argument, FunctionExpression(function: .arcTangent, expression: argument)
            ]),
            MultiplicationExpression(expressions: [
                ValueExpression(value: Rational(1, 2)),
                FunctionExpression(function: .logarithm, expression:
                    AdditionExpression(expressions: [
                        ValueExpression(value: Rational(1)),
                        MultiplicationExpression(expressions: [argument, argument])
                    ])
                ),
                ValueExpression(value: Rational(-1))
            ])
        ])
    }
}

class ExponentialFunction: Function {
   init() { super.init(name: "exp", inverse: "ln") }
   
// Function ========================================================================================
   override func differentiate(argument: Expression) -> Expression {
       FunctionExpression(function: .exponential, expression: argument)
   }
   override func integrate(argument: Expression) -> Expression {
       FunctionExpression(function: .exponential, expression: argument)
   }
}

class LogarithmFunction: Function {
    init() { super.init(name: "ln", inverse: "exp") }
        
// Function ========================================================================================
    override func differentiate(argument: Expression) -> Expression {
        PowerExpression(expression: argument, power: ValueExpression(value: Rational(-1)))
    }
    override func integrate(argument: Expression) -> Expression {
        AdditionExpression(expressions: [
            MultiplicationExpression(expressions: [
                argument,
                FunctionExpression(function: .logarithm, expression: argument)
            ]),
            MultiplicationExpression(expressions: [
                argument,
                ValueExpression(value: Rational(-1))
            ])
        ])
    }
}

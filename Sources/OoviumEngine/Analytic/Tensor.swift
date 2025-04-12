//
//  Tensor.swift
//  OoviumEngine
//
//  Created by Joe Charlier on 4/8/25.
//

class Tensor: Value, CustomStringConvertible {
    let dimensions: Int
    let rank: Int
    let components: [Expression]
    let isCovariant: [Bool]
    
    init(dimensions: Int, rank: Int, components: [Expression], isCovariant: [Bool]) {
        self.dimensions = dimensions
        self.rank = rank
        self.components = components
        self.isCovariant = isCovariant
    }
    
    subscript(indices: Int...) -> Expression {
        get {
            guard indices.count == rank else { fatalError() }
            var index = 0
            for i in 0..<rank { index += indices[i] * AnainMath.pow(dimensions, rank-i-1) }
            return components[index]
        }
    }
    
    func calculateJacobian(variables: [String]) -> Expression {
        var jacobianComponents: [Expression] = []
        
        for component in components {
            for variable in variables {
                jacobianComponents.append(component.differentiate(with: Variable(name: variable)))
            }
        }
        
        return ValueExpression(value: Tensor(dimensions: variables.count, rank: 2, components: jacobianComponents, isCovariant: [true, false]))
    }
    
    func substitute(_ vector: Tensor) -> Tensor {
        let variableNames = ["x", "y"]
        
        var newComponents: [Expression] = []
        for component in components {
            var result = component
            for (index, name) in variableNames.enumerated() {
                if index < vector.components.count {
                    if let valueExpr = vector.components[index] as? ValueExpression {
                        result = result.substitute(variable: name, with: valueExpr.value)
                    }
                }
            }
            newComponents.append(result.reduce())
        }
        
        return Tensor(
            dimensions: dimensions,
            rank: rank,
            components: newComponents,
            isCovariant: isCovariant
        )
    }
    
//    static prefix func - (a: Tensor) -> Tensor { Tensor(-a.numerator, a.denominator) }
//    static func + (_ a: Tensor, _ b: Tensor) -> Tensor { Rational(a.numerator*b.denominator + b.numerator*a.denominator, a.denominator*b.denominator).reduced() }
    
    static func * (lhs: Tensor, rhs: Rational) -> Tensor {
        let components = lhs.components.map { MultiplicationExpression(expressions: [$0, ValueExpression(value: rhs)]).reduce()}
        return Tensor(dimensions: lhs.dimensions, rank: lhs.rank, components: components, isCovariant: lhs.isCovariant)
    }
    static func * (lhs: Rational, rhs: Tensor) -> Tensor { rhs * lhs }
    
    static func * (lhs: Tensor, rhs: Tensor) -> Tensor {
        if lhs.rank == 2 && rhs.rank == 1 && lhs.dimensions == rhs.dimensions {
            var resultComponents: [Expression] = []
            
            for i in 0..<lhs.dimensions {
                var sum: Expression = ValueExpression(value: Rational(0))
                
                for j in 0..<lhs.dimensions {
                    let matrixIndex = i * lhs.dimensions + j
                    let product = MultiplicationExpression(expressions: [lhs.components[matrixIndex], rhs.components[j]]).reduce()
                    
                    sum = AdditionExpression(expressions: [sum, product]).reduce()
                }
                
                resultComponents.append(sum)
            }
            
            return Tensor(dimensions: rhs.dimensions, rank: 1, components: resultComponents, isCovariant: rhs.isCovariant)
        }
        
        fatalError("Unsupported tensor multiplication")
    }
    static func *= (lhs: inout Tensor, rhs: Tensor) { lhs = lhs * rhs }
    
//    static func / (_ a: Int, _ b: Rational) -> Rational { Rational(a*b.denominator, b.numerator) }
//    static func == (_ a: Rational, _ b: Rational) -> Bool {
//        let aR = a.reduced()
//        let bR = b.reduced()
//        return aR.numerator == bR.numerator && aR.denominator == bR.denominator
//    }
//    static func != (_ a: Rational, _ b: Rational) -> Bool { !(a == b) }
    
// CustomStringConvertable =========================================================================
    var description: String {
        if rank == 0 {
            return components[0].description
        } else if rank == 1 {
            var result = "["
            for i in 0..<dimensions {
                result += components[i].description
                if i < dimensions - 1 {
                    result += ", "
                }
            }
            result += "]"
            return result
        } else {
            var result = "["
            let componentsPerSlice = AnainMath.pow(dimensions, rank - 1)
            
            for i in 0..<dimensions {
                let start = i * componentsPerSlice
                let end = start + componentsPerSlice
                let slice = components[start..<end]
                
                result += "["
                for (j, component) in slice.enumerated() {
                    result += component.description
                    if j < slice.count - 1 {
                        result += ", "
                    }
                }
                result += "]"
                
                if i < dimensions - 1 {
                    result += ",\n "
                }
            }
            result += "]"
            return result
        }
    }
}

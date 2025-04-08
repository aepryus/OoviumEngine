//
//  Vector.swift
//  OoviumEngine
//
//  Created by Joe Charlier on 4/8/25.
//

class Vector: Value {
    let components: [Expression]
    let isCovariant: Bool
    
    init(_ components: [Expression], isCovariant: Bool = false) {
        self.components = components
        self.isCovariant = isCovariant
    }
    
    var dimensions: Int { components.count }
    
    static func + (lhs: Vector, rhs: Vector) -> Vector {
        guard lhs.isCovariant == rhs.isCovariant && lhs.dimensions == rhs.dimensions else { fatalError() }
        
        var components: [Expression] = []
        
        for i in 0..<lhs.dimensions {
            let expression: Expression = AdditionExpression(expressions: [lhs.components[i], rhs.components[i]]).reduce()
            components.append(expression)
        }
        
        return Vector(components, isCovariant: lhs.isCovariant)
    }
    static func * (lhs: Vector, rhs: Real) -> Vector {
        var components: [Expression] = []
        
        for i in 0..<lhs.dimensions {
            let expression: Expression = MultiplicationExpression(expressions: [lhs.components[i], ValueExpression(value: rhs)]).reduce()
            components.append(expression)
        }

        return Vector(components, isCovariant: lhs.isCovariant)
    }
    static func * (lhs: Real, rhs: Vector) -> Vector { rhs * lhs }
    static func * (lhs: Vector, rhs: Rational) -> Vector { lhs * Real(ValueExpression(value: rhs)) }
    static func * (lhs: Rational, rhs: Vector) -> Vector { rhs * Real(ValueExpression(value: lhs)) }
}

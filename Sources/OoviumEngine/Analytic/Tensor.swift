//
//  Tensor.swift
//  OoviumEngine
//
//  Created by Joe Charlier on 4/8/25.
//

class Tensor: Value {
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
        return ValueExpression(value: Rational(0))
    }
}

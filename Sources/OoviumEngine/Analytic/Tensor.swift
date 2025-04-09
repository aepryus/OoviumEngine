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
        // Create a matrix of derivatives (rank 2 tensor)
        var jacobianComponents: [Expression] = []
        
        // For each component in the tensor
        for component in components {
            // For each variable
            for variableName in variables {
                let variable = Variable(name: variableName)
                // Calculate the partial derivative of this component with respect to this variable
                let derivative = component.differentiate(with: variable)
                jacobianComponents.append(derivative)
            }
        }
        
        // Return a tensor representing the Jacobian matrix
        return ValueExpression(value: Tensor(
            dimensions: variables.count,
            rank: 2,
            components: jacobianComponents,
            isCovariant: [true, false]
        ))
    }
    
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

//
//  Transform.swift
//  OoviumEngine
//
//  Created by Joe Charlier on 1/24/23.
//  Copyright © 2023 Aepryus Software. All rights reserved.
//

import Acheron
import Aegean
import Foundation

public class Transform: Aexon {
    @objc public var name: String = ""
    @objc public var dimensions: [Dimension] = []

    public var token: Token = .add
    public var recipeToken: Token = .add

    public init(aexel: Aexel, name: String) {
        self.name = name
        super.init(parent: aexel)
    }
    public required init(attributes: [String : Any], parent: Domain? = nil) {
        super.init(attributes: attributes, parent: parent)
    }

    public var coordinate: Coordinate { parent as! Coordinate }

// Token keys (Citadel-side wiring) =================================================================
    // Source-system parameters: e.g. for spherical toCart these are θ, ϕ, r.
    public func inputTokenKey(at i: Int) -> TokenKey {
        TokenKey(code: .va, tag: "\(coordinate.key).\(name).\(dimensions[i].name)")
    }
    // Chain output for the i-th formula (where the chain's result lands in citadel memory).
    // Distinct from the recipe's variableTokenKey so ChainCore and RecipeCore don't collide.
    public func chainOutputTokenKey(at i: Int) -> TokenKey {
        TokenKey(code: .va, tag: "\(coordinate.key).\(name).f\(i)")
    }
    // Recipe output (a separate slot owned by the RecipeCore).
    public func outputVariableTokenKey(at i: Int) -> TokenKey {
        TokenKey(code: .va, tag: "\(coordinate.key).\(name).out\(i)")
    }
    public func outputMechlikeTokenKey(at i: Int) -> TokenKey {
        TokenKey(code: .ml, tag: "\(coordinate.key).\(name).out\(i)")
    }

    public override var tokenKeys: [TokenKey] {
        var keys: [TokenKey] = []
        for i in 0..<dimensions.count {
            keys.append(inputTokenKey(at: i))
            keys.append(chainOutputTokenKey(at: i))
            keys.append(outputVariableTokenKey(at: i))
            keys.append(outputMechlikeTokenKey(at: i))
        }
        return keys
    }

    public override func createCores() -> [Core] {
        var cores: [Core] = []
        for i in 0..<dimensions.count {
            let key: TokenKey = inputTokenKey(at: i)
            let param: StaticParameter = StaticParameter(tokenKey: key, fogKey: nil, name: dimensions[i].name)
            cores.append(ParameterCore(parameter: param))
        }
        for dim in dimensions where dim.chain != nil {
            cores.append(ChainCore(chain: dim.chain))
        }
        for i in 0..<dimensions.count where dimensions[i].chain != nil {
            cores.append(RecipeCore(delegate: TransformRecipeDelegate(transform: self, outputIndex: i)))
        }
        return cores
    }

// Aexon ===========================================================================================
    public override func newNo(type: String) -> Int { dimensions.count + 1 }

// Domain ==========================================================================================
    public override var properties: [String] { super.properties + ["name", "dimensions"] }
}

// One per output formula in a Transform. Compiles dimensions[i].chain into a Recipe parameterized
// by the Transform's input slots; the Recipe writes its result into the i-th output slot.
class TransformRecipeDelegate: RecipeDelegate {
    unowned let transform: Transform
    let outputIndex: Int

    init(transform: Transform, outputIndex: Int) {
        self.transform = transform
        self.outputIndex = outputIndex
    }

// RecipeDelegate ==================================================================================
    var name: String { "\(transform.coordinate.key).\(transform.name).out\(outputIndex)" }
    var variableTokenKey: TokenKey { transform.outputVariableTokenKey(at: outputIndex) }
    var mechlikeTokenKey: TokenKey { transform.outputMechlikeTokenKey(at: outputIndex) }
    var params: [TokenKey] {
        (0..<transform.dimensions.count).map { transform.inputTokenKey(at: $0) }
    }
    var resultChain: Chain { transform.dimensions[outputIndex].chain }

// VariableTokenDelegate ===========================================================================
    var alias: String?
}

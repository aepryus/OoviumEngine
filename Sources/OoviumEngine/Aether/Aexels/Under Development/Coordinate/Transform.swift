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

public class Transform: Aexon, Web {
    @objc public var name: String = ""
    @objc public var dimensions: [Dimension] = []
    
    public var token: Token = .add
    public var recipeToken: Token = .add
    
//    public lazy var tower: Tower = coordinate.aether.state.createTower(tag: "key", towerDelegate: self)
    
    public init(aexel: Aexel, name: String) {
        self.name = name
        super.init(parent: aexel)
    }
    public required init(attributes: [String : Any], parent: Domain? = nil) {
        super.init(attributes: attributes, parent: parent)
    }
    
    var coordinate: Coordinate { parent as! Coordinate }
    
//    public var towers: Set<Tower> {
//        var towers = Set<Tower>()
//        dimensions.forEach {
//            towers.insert($0.tower)
//            towers.insert($0.chain.tower)
//        }
//        return towers.union([tower])
//    }
    
    public var recipes: [UnsafeMutablePointer<Recipe>] = []
    
    public func compileRecipes() {
//        let memory: UnsafeMutablePointer<Memory> = AEMemoryCreateClone(coordinate.aether.state.memory)
//        AEMemoryClear(memory)
//        
//        dimensions.forEach { AEMemorySetValue(memory, $0.tower.index, 0) }
//        
//        recipes = []
//        dimensions.forEach {
//            let recipe: UnsafeMutablePointer<Recipe> = Math.compile(result: $0.chain.tower, memory: memory)
//            recipes.append(recipe)
//            AERecipeSignature(recipe, AEMemoryIndexForName(memory, "\(coordinate.key).\(key).\($0.key)".toInt8()), UInt8(dimensions.count))
//        }
//        
//        let indexes: [mnimi] = dimensions.map {AEMemoryIndexForName(memory, "\(coordinate.key).\(key).\($0.key)".toInt8()) }
//        
//        recipes.forEach {
//            for i in 0...2 { $0.pointee.params[i] = mnimi(indexes[i]) }
//        }
    }

    
// Events ==========================================================================================
    public override func onLoaded() {
//        dimensions.forEach { $0.chain.tower.tailForWeb = self }
    }

// Aexon ===========================================================================================
    public override func newNo(type: String) -> Int { dimensions.count + 1 }

// Domain ==========================================================================================
    public override var properties: [String] { super.properties + ["name", "dimensions"] }
}

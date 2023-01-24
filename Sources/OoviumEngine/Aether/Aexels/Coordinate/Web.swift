//
//  Web.swift
//  OoviumEngine
//
//  Created by Joe Charlier on 1/24/23.
//  Copyright © 2023 Aepryus Software. All rights reserved.
//

import Acheron
import Foundation

public class Web: Domain, TowerDelegate {
    @objc public var name: String = ""
    @objc public var dimensions: [Dimension] = []
    
    public var token: Token = .add
    public var recipeToken: Token = .add
    
    public lazy var tower: Tower = coordinate.aether.createTower(tag: "key", towerDelegate: self)
    
    public init(aexel: Aexel, name: String) {
        self.name = name
        super.init(parent: aexel)
    }
    public required init(attributes: [String : Any], parent: Domain? = nil) {
        super.init(attributes: attributes, parent: parent)
    }
    
    var coordinate: Coordinate { parent as! Coordinate }
    var key: String { name }
    
    public var towers: Set<Tower> {
        var towers = Set<Tower>()
        dimensions.forEach {
            towers.insert($0.tower)
            towers.insert($0.chain.tower)
        }
        return towers.union([tower])
    }
    
// Events ==========================================================================================
    public override func onLoaded() {
        dimensions.forEach { $0.chain.tower.tailForWeb = self }
    }
    
// Domain ==========================================================================================
    override public var properties: [String] { super.properties + ["name", "dimensions"] }
}

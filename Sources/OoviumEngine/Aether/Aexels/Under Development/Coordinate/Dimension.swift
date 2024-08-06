//
//  Coordinate.swift
//  OoviumEngine
//
//  Created by Joe Charlier on 1/14/23.
//  Copyright © 2023 Aepryus Software. All rights reserved.
//

import Acheron
import Foundation

public class Dimension: Aexon, VariableTokenDelegate {
    @objc public var name: String = ""
    @objc public var chain: Chain!
    
//    public lazy var tower: Tower = { coordinate.aether.state.createTower(tag: "\(coordinate.key).\(web.key).\(key)", towerDelegate: self, tokenDelegate: self) }()
    
    public init(web: Transform, name: String) {
        self.name = name
        super.init(parent: web)
    }
    required init(attributes: [String : Any], parent: Domain?) {
        super.init(attributes: attributes, parent: parent)
    }

    
    var web: Transform { parent as! Transform }
    var coordinate: Coordinate { web.coordinate }

// Events ==========================================================================================
    public override func onLoad() {
//        tower.web = web
//        coordinate.aether.inject(chain: chain, tag: "\(coordinate.key).\(web.key).\(key).result")
    }
    
// Aexon ===========================================================================================
    public override var code: String { "d" }

// Domain ==========================================================================================
    public override var properties: [String] { super.properties + ["name", "chain"] }
    
// Core ===================================================================================
    func renderDisplay(tower: Tower) -> String { name }
    
// VariableTokenDelegate ===========================================================================
    public var alias: String? { name }
}

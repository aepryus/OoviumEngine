//
//  Coordinate.swift
//  OoviumEngine
//
//  Created by Joe Charlier on 1/14/23.
//  Copyright © 2023 Aepryus Software. All rights reserved.
//

import Acheron
import Foundation

public class Dimension: Domain, TowerDelegate, VariableTokenDelegate {
    @objc public var name: String = ""
    @objc public var no: Int = 0
    @objc public var chain: Chain = Chain()
    
    public lazy var tower: Tower = { coordinate.aether.createTower(tag: "\(coordinate.key).\(key)", towerDelegate: self, tokenDelegate: self) }()
    
    public init(web: Web, name: String, no: Int) {
        self.name = name
        self.no = no
        super.init(parent: web)
    }
    required init(attributes: [String : Any], parent: Domain?) {
        super.init(attributes: attributes, parent: parent)
    }

    
    var web: Web { parent as! Web }
    var coordinate: Coordinate { web.coordinate }
    var key: String { name }

// Events ==========================================================================================
    public override func onLoad() {
        tower.web = web
        chain.tower = coordinate.aether.createTower(tag: "\(coordinate.key).\(web.key).\(key)", towerDelegate: chain)
    }
    
// Domain ==========================================================================================
    override public var properties: [String] { super.properties + ["name", "no", "chain"] }
    
// TowerDelegate ===================================================================================
    func renderDisplay(tower: Tower) -> String { name }
    
// VariableTokenDelegate ===========================================================================
    public var alias: String? { name }
}

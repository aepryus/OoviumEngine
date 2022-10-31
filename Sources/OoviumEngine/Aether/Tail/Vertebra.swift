//
//  Vertebra.swift
//  Oovium
//
//  Created by Joe Charlier on 12/30/16.
//  Copyright © 2016 Aepryus Software. All rights reserved.
//

import Acheron
import Foundation

public final class Vertebra: Domain, TowerDelegate, VariableTokenDelegate {
	@objc public dynamic var name: String = ""
    @objc public dynamic var no: Int = 0
	@objc public dynamic var chain: Chain = Chain()

//    var def: Def = RealDef.def

    public lazy var tower: Tower = { tail.aether.createTower(tag: "\(tail.key).\(key)", towerDelegate: self, tokenDelegate: self) }()

// Inits ===========================================================================================
	init(tail: Tail, name: String) {
		self.name = name
		super.init()
		parent = tail
	}
	required init(attributes: [String : Any], parent: Domain?) {
		super.init(attributes: attributes, parent: parent)
	}

	var tail: Tail { parent as! Tail }
    var key: String {
        if no == 0 { fatalError() }
        return "i\(no)"
    }

// Events ==========================================================================================
	public override func onLoad() {
        chain.tower = tail.aether.createTower(tag: "\(tail.key).\(key).chain", towerDelegate: chain)
		tower.web = tail.web
	}
	
// Domain ==========================================================================================
	public override var properties: [String] {
		return super.properties + ["name", "no", "chain"]
	}
	
// TowerDelegate ===================================================================================
    func renderDisplay(tower: Tower) -> String { name }
    
// VariableTokenDelegate ===========================================================================
    public var alias: String? { name }
}

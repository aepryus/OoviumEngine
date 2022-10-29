//
//  Vertebra.swift
//  Oovium
//
//  Created by Joe Charlier on 12/30/16.
//  Copyright © 2016 Aepryus Software. All rights reserved.
//

import Acheron
import Foundation

public final class Vertebra: Domain, TowerDelegate {
	@objc public dynamic var name: String = ""
	var def: Def = RealDef.def
	@objc public dynamic var chain: Chain = Chain() {
		didSet {
            chain.tower = tail.aether.createTower(tag: "TaV_\(tail.no).\(name)", towerDelegate: chain)
		}
	}
		
	public lazy var tower: Tower = { tail.aether.createTower(tag: "\(tail.name).\(name)", towerDelegate: self) }()

// Inits ===========================================================================================
	init(tail: Tail, name: String) {
		self.name = name
		super.init()
		parent = tail
        chain.tower = tail.aether.createTower(tag: "TaV_\(tail.no).\(name)", towerDelegate: chain)
	}
	required init(attributes: [String : Any], parent: Domain?) {
		super.init(attributes: attributes, parent: parent)
        chain.tower = tail.aether.createTower(tag: "TaV_\(tail.no).\(name)", towerDelegate: chain)
	}

	var tail: Tail { parent as! Tail }

// Events ==========================================================================================
	public override func onLoad() {
		tower.web = tail.web
	}
	
// Domain ==========================================================================================
	public override var properties: [String] {
		return super.properties + ["name", "chain"]
	}
	
// TowerDelegate ===================================================================================
    func renderDisplay(tower: Tower) -> String { name }
}

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
	@objc public dynamic var name: String = "" {
		didSet {
			guard let tail = parent as? Tail else {return}
			tail.aether.rekey(token: tower.variableToken, tag: "\(tail.name).\(name)")
			tail.aether.rekey(token: chain.tower.variableToken, tag: "TaV_\(tail.no).\(name)")
			tower.variableToken.label = name
		}
	}
	var def: Def = RealDef.def
	@objc public dynamic var chain: Chain = Chain() {
		didSet {
			chain.tower = Tower(aether: tail.aether, token: tail.aether.variableToken(tag: "TaV_\(tail.no).\(name)"), delegate: chain)
		}
	}
		
	public lazy var tower: Tower = {Tower(aether: tail.aether, token: tail.aether.variableToken(tag: "\(tail.name).\(name)"), delegate: self)}()

// Inits ===========================================================================================
	init(tail: Tail, name: String) {
		self.name = name
		super.init()
		parent = tail
		chain.tower = Tower(aether: tail.aether, token: tail.aether.variableToken(tag: "TaV_\(tail.no).\(name)"), delegate: chain)
	}
	required init(attributes: [String : Any], parent: Domain?) {
		super.init(attributes: attributes, parent: parent)
		chain.tower = Tower(aether: tail.aether, token: tail.aether.variableToken(tag: "TaV_\(tail.no).\(name)"), delegate: chain)
	}

	var tail: Tail {
		return parent as! Tail
	}

// Events ==========================================================================================
	public override func onLoad() {
		tower.web = tail.web
	}
	
// Domain ==========================================================================================
	public override var properties: [String] {
		return super.properties + ["name", "chain"]
	}
	
// TowerDelegate ===================================================================================
	func renderDisplay(tower: Tower) -> String {
		return name
	}
}

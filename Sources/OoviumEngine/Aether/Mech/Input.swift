//
//  Input.swift
//  Oovium
//
//  Created by Joe Charlier on 12/30/16.
//  Copyright © 2016 Aepryus Software. All rights reserved.
//

import Acheron
import Foundation

public final class Input: Domain, TowerDelegate {
	@objc public dynamic var name: String = "" {
		didSet {
			guard let mech = parent as? Mech else {return}
			mech.aether.rekey(token: tower.variableToken, tag: "\(mech.name).\(name)")
			tower.variableToken.label = name
		}
	}
	var def: Def = RealDef.def
	
	lazy var tower: Tower = {Tower(aether: mech.aether, token: mech.aether.variableToken(tag: "\(mech.name).\(name)"), delegate: self)}()
	
	init(mech: Mech, name: String) {
		self.name = name
		super.init()
		parent = mech
	}
	required init(attributes: [String : Any], parent: Domain?) {
//		let name: String = attributes["name"] as! String
		super.init(attributes: attributes, parent: parent)
	}
	
	var mech: Mech {
		return parent as! Mech
	}
	
// Events ==========================================================================================
	public override func onLoad() {
		tower.web = mech.web
	}

// Domain ==========================================================================================
	public override var properties: [String] {
		return super.properties + ["name"]
	}
	
// TowerDelegate ===================================================================================
	func renderDisplay(tower: Tower) -> String {
		return name
	}
}

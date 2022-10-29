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
    @objc public dynamic var name: String = ""
    @objc public dynamic var no: Int = 0
    
	var def: Def = RealDef.def
	
	public lazy var tower: Tower = { mech.aether.createTower(tag: "\(mech.key).\(key)", towerDelegate: self) }()
	
	init(mech: Mech, name: String) {
		self.name = name
		super.init()
		parent = mech
	}
	required init(attributes: [String : Any], parent: Domain?) {
//		let name: String = attributes["name"] as! String
		super.init(attributes: attributes, parent: parent)
	}
	
	var mech: Mech { parent as! Mech }
    var key: String {
        if no == 0 { fatalError() }
        return "i\(no)"
    }
	
// Events ==========================================================================================
	public override func onLoad() {
		tower.web = mech.web
	}

// Domain ==========================================================================================
	public override var properties: [String] { super.properties + ["name", "no"] }
	
// TowerDelegate ===================================================================================
	func renderDisplay(tower: Tower) -> String { name }
}

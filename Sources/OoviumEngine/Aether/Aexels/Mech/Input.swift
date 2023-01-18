//
//  Input.swift
//  Oovium
//
//  Created by Joe Charlier on 12/30/16.
//  Copyright © 2016 Aepryus Software. All rights reserved.
//

import Acheron
import Foundation

public final class Input: Domain, TowerDelegate, VariableTokenDelegate {
    @objc public dynamic var name: String = "" {
        didSet {
            guard name != "" else { name = oldValue; return }
            var newName: String = name
            var i: Int = 2
            while mech.inputs.first(where: { $0 !== self && $0.name == newName }) != nil {
                newName = "\(name)\(i)"
                i += 1
            }
            name = newName
        }
    }
    @objc public dynamic var no: Int = 0
    
//	var def: Def = RealDef.def
	
    public lazy var tower: Tower = { mech.aether.createTower(tag: "\(mech.key).\(key)", towerDelegate: self, tokenDelegate: self) }()
	
    init(mech: Mech, name: String, no: Int) {
		self.name = name
        self.no = no
		super.init(parent: mech)
	}
	required init(attributes: [String : Any], parent: Domain?) {
		super.init(attributes: attributes, parent: parent)
	}
	
	var mech: Mech { parent as! Mech }
    var key: String {
        if no == 0 { fatalError() }
        return "i\(no)"
    }
    
    private func wire() {
        tower.web = mech.web
    }
	
// Events ==========================================================================================
    public override func onCreate() { wire() }
	public override func onLoad() { wire() }
    public override func onRemoved() { mech.aether.destroy(tower: tower) }

// Domain ==========================================================================================
	public override var properties: [String] { super.properties + ["name", "no"] }
	
// TowerDelegate ===================================================================================
	func renderDisplay(tower: Tower) -> String { name }
    
// VariableTokenDelegate ===========================================================================
    public var alias: String? { name }
}

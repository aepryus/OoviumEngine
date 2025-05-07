//
//  Input.swift
//  Oovium
//
//  Created by Joe Charlier on 12/30/16.
//  Copyright © 2016 Aepryus Software. All rights reserved.
//

import Acheron
import Foundation

public class Input: Aexon, ParameterDelegate {
    @objc public dynamic var name: String = "" {
        didSet {
            if name == "" { name = oldValue }
            else { name = Aether.ensureUniquiness(name: name, names: mech.inputs.filter({ $0 !== self }).map({ $0.name })) }
        }
    }
    
    public lazy var tokenKey: TokenKey = TokenKey(code: .va, tag: fullKey)
	
    init(mech: Mech, name: String) {
		self.name = name
    	super.init(parent: mech)
	}
	required init(attributes: [String : Any], parent: Domain?) {
		super.init(attributes: attributes, parent: parent)
	}

	var mech: Mech { parent as! Mech }
    
// Aexon ===========================================================================================
    public override var code: String { "i" }
    public override var tokenKeys: [TokenKey] { [tokenKey] }
    public override func createCores() -> [Core] { [ParameterCore(parameter: self)] }

// Domain ==========================================================================================
	public override var properties: [String] { super.properties + ["name"] }
    
// ParameterDelegate ===============================================================================
    var fogKey: TokenKey? { mech.mechlikeTokenKey }

// VariableTokenDelegate ===========================================================================
    public var alias: String? { name }
}

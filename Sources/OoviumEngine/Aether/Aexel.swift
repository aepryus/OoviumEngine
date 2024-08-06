//
//  Aexel.swift
//  Oovium
//
//  Created by Joe Charlier on 12/31/16.
//  Copyright © 2016 Aepryus Software. All rights reserved.
//

import Acheron
import Foundation

public class Aexel: Aexon {
	@objc public var name: String = ""
	@objc public var x: Double = 0.0
	@objc public var y: Double = 0.0

// Inits ===========================================================================================
	public required init(at: V2, aether: Aether) {
		x = at.x
		y = at.y
        super.init(parent: aether)
	}
	public required init(attributes: [String:Any], parent: Domain?) {
		super.init(attributes: attributes, parent: parent)
	}
    
// Computed ========================================================================================
    public override var aexel: Aexel { self }
    public override var aether: Aether { parent as! Aether }
    
// Aexon ===========================================================================================
    override var fullKey: String { key }

// Domain ==========================================================================================
	override open var properties: [String] { super.properties + ["name", "x", "y"] }
}

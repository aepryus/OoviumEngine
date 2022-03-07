//
//  Aexel.swift
//  Oovium
//
//  Created by Joe Charlier on 12/31/16.
//  Copyright © 2016 Aepryus Software. All rights reserved.
//

import Acheron
import Foundation

public class Aexel: Domain {
	@objc public var no: Int = 0
	@objc var name: String = ""
	@objc public var x: Double = 0.0
	@objc public var y: Double = 0.0
	
	public var aether: Aether {
		return parent as! Aether
	}

	var towers: Set<Tower> {
		return []
	}

// Inits ===========================================================================================
	public required init(no: Int, at: V2, aether: Aether) {
		self.no = no
		x = at.x
		y = at.y
		super.init(parent: aether)
	}
	public required init(attributes: [String:Any], parent: Domain?) {
		super.init(attributes: attributes, parent: parent)
	}

// Domain ==========================================================================================
	override open var properties: [String] {
		return super.properties + ["no" ,"name", "x", "y"]
	}
}

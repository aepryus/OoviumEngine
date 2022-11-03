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
	@objc public var name: String = ""
	@objc public var x: Double = 0.0
	@objc public var y: Double = 0.0

    var code: String { fatalError() }
    var key: String { "\(code)\(no)" }
	public var aether: Aether { parent as! Aether }
	public var towers: Set<Tower> { [] }

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
	override open var properties: [String] { super.properties + ["no" ,"name", "x", "y"] }
}

//
//  State.swift
//  Oovium
//
//  Created by Joe Charlier on 12/30/16.
//  Copyright © 2016 Aepryus Software. All rights reserved.
//

import Acheron
import Foundation

public final class State: Domain {
//	var color: OOColor = .clear
	@objc public var no: Int = 0
	@objc public var color: Int = 0
	
	public init(no: Int, color: OOColor) {
		self.no = no
		self.color = color.rawValue
		super.init()
	}
	public required init(attributes: [String : Any], parent: Domain?) {
		super.init(attributes: attributes, parent: parent)
	}
	
// Domain ==========================================================================================
	override public var properties: [String] {
		return super.properties + ["no", "color"]
	}
}

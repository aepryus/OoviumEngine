//
//  Field.swift
//  Oovium
//
//  Created by Joe Charlier on 12/30/16.
//  Copyright © 2016 Aepryus Software. All rights reserved.
//

import Acheron
import Foundation

public final class Field: Aexon {
	@objc public dynamic var name: String = ""
	@objc public dynamic var typeName: String = ""
	@objc public dynamic var orderNo: Int = 0
	
	var def: Def = RealDef.def

// Domain ==========================================================================================
	override public var properties: [String] {
		return super.properties + ["name", "typeName", "orderNo"]
	}
}

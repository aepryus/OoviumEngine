//
//  Field.swift
//  Oovium
//
//  Created by Joe Charlier on 12/30/16.
//  Copyright © 2016 Aepryus Software. All rights reserved.
//

import Acheron
import Foundation

final class Field: Domain {
	@objc dynamic var name: String = ""
	@objc dynamic var typeName: String = ""
	@objc dynamic var orderNo: Int = 0
	
	var def: Def = RealDef.def

// Domain ==========================================================================================
	override public var properties: [String] {
		return super.properties + ["name", "typeName", "orderNo"]
	}
}

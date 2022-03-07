//
//  StringDef.swift
//  Oovium
//
//  Created by Joe Charlier on 10/2/16.
//  Copyright © 2016 Aepryus Software. All rights reserved.
//

import Aegean
import Foundation

public final class StringDef: Def {
	public static let def = StringDef()
	
	init() {
		super.init(name: "String", key:"str", properties: ["s"], order:5)
	}
	
// Def =============================================================================================
	override func format(obj: Obj) -> String {
		let a = obj.a.p.assumingMemoryBound(to: UInt8.self)
		let string = String(cString: a)
		return string
	}
}

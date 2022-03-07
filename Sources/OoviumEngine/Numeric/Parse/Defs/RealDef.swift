//
//  RealDef.swift
//  Oovium
//
//  Created by Joe Charlier on 10/1/16.
//  Copyright © 2016 Aepryus Software. All rights reserved.
//

import Aegean
import Foundation

public final class RealDef: Def {
	public static let def = RealDef()
	
	init() {
		super.init(name: "Number", key:"num", properties: ["x"], order:1)
	}
	
// Def =============================================================================================
	override func format(obj: Obj) -> String {
		let value: Double = obj.a.x
		
		if (abs(value) < 0.00000001 && value != 0) || abs(value) > 999999999999 {
			return Def.scientificFormatter.string(from: NSNumber(value: value))!
		}
			
		return Def.normalFormatter.string(from: NSNumber(value: value))!
	}
}

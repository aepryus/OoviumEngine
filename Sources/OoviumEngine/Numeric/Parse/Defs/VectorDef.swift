//
//  VectorDef.swift
//  Oovium
//
//  Created by Joe Charlier on 10/1/16.
//  Copyright © 2016 Aepryus Software. All rights reserved.
//

import Aegean
import Foundation

public final class VectorDef: Def {
	public static let def = VectorDef(name:"vector", key:"vct", properties:["x","y","z"], order:3)

// Def =============================================================================================
	override func format(obj: Obj) -> String {
		var sb: String = ""
		
		let x: Double = obj.a.x
		let y: Double = obj.b.x
		let z: Double = obj.c.x
		
		sb += Def.normalFormatter.string(from: NSNumber(value: x))!
		sb += ", "
		sb += Def.normalFormatter.string(from: NSNumber(value: y))!
		sb += ", "
		sb += Def.normalFormatter.string(from: NSNumber(value: z))!

		return sb
	}
}

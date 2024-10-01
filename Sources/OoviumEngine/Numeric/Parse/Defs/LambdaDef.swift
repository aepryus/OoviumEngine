//
//  LambdaDef.swift
//  Oovium
//
//  Created by Joe Charlier on 5/11/20.
//  Copyright © 2020 Aepryus Software. All rights reserved.
//

import Aegean
import Foundation

public class LambdaDef: Def {
	public static let def = LambdaDef(name:"lambda", key:"lmb", properties:["f"], order: 6)
	
// Def =============================================================================================
	override func format(obj: Obj) -> String {
		let lambda = UnsafeMutablePointer<Lambda>(OpaquePointer(obj.a.p))!
		return String(cString: lambda.pointee.label)
	}
}

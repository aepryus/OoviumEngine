//
//  RecipeDef.swift
//  Oovium
//
//  Created by Joe Charlier on 10/1/16.
//  Copyright © 2016 Aepryus Software. All rights reserved.
//

import Aegean
import Foundation

public final class RecipeDef: Def {
	public static let def = RecipeDef(name:"recipe", key:"rcp", properties:["f"], order: 4)
	
// Def =============================================================================================
	override func format(obj: Obj) -> String {
		let recipe = UnsafeMutablePointer<Recipe>(OpaquePointer(obj.a.p))!
		return String(cString: recipe.pointee.name)
	}
}

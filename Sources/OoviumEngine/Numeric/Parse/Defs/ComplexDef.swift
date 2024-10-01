//
//  ComplexDef.swift
//  Oovium
//
//  Created by Joe Charlier on 10/1/16.
//  Copyright © 2016 Aepryus Software. All rights reserved.
//

import Aegean
import Foundation

public class ComplexDef: Def {
	public static let def = ComplexDef()
	
	init() {
		super.init(name: "Complex", key:"cpx", properties: ["r", "i"], order:2)
	}

// Def =============================================================================================
	override func format(obj: Obj) -> String {
		let r: Double = obj.a.x
		let i: Double = obj.b.x
		
		let rt: String = Def.normalFormatter.string(from: NSNumber(value: r))!
        let it: String = Def.normalFormatter.string(from: NSNumber(value: i))!

        var sb: String = ""
        
        if rt != "0" || it == "0" { sb += rt }
        if it != "0" {
            if rt != "0" && i > 0 { sb += "+" }
            if it == "-1" { sb += "-" }
            else if it != "1" { sb += it }
            sb += "i"
        }
        
		return sb
	}
}

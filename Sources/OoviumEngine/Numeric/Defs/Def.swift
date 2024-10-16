//
//  Def.swift
//  Oovium
//
//  Created by Joe Charlier on 10/1/16.
//  Copyright © 2016 Aepryus Software. All rights reserved.
//

import Aegean
import Foundation

public class Def {
	public let name: String
	public let key: String
	public let properties: [String]
	public let order: Int
	
	init(name: String, key: String, properties: [String], order: Int = 9) {
		self.name = name
		self.key = key
		self.properties = properties
		self.order = order
	}
	
	static let normalFormatter: NumberFormatter =  {
		let formatter = NumberFormatter()
		formatter.positiveFormat = "#,##0.########"
		formatter.negativeFormat = "-#,##0.########"
		return formatter
	}()
	static let scientificFormatter: NumberFormatter =  {
		let formatter = NumberFormatter()
		formatter.maximumIntegerDigits = 1
		formatter.maximumFractionDigits = 8
		formatter.exponentSymbol = "e"
		formatter.numberStyle = .scientific
		return formatter
	}()

	func format(obj: Obj) -> String { "override format(obj: Obj)" }

	static func format(obj: Obj) -> String {
		if let def: Def = defs[obj.type.rawValue] { return def.format(obj: obj) }
		return "Def not found [\(obj.type.rawValue)]"
	}

	private static var defs: [UInt32:Def] = [
		AETypeReal.rawValue:RealDef.def,
		AETypeComplex.rawValue:ComplexDef.def,
		AETypeVector.rawValue:VectorDef.def,
		AETypeString.rawValue:StringDef.def,
		AETypeLambda.rawValue:LambdaDef.def,
		AETypeRecipe.rawValue:RecipeDef.def
	]
    static func def(obj: Obj) -> Def? { defs[obj.type.rawValue] }
}

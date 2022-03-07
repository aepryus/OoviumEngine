//
//  Obje.swift
//  Oovium
//
//  Created by Joe Charlier on 2/25/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import Aegean
import Foundation

public class Obje {
	var obj: Obj
	
	init(memory: UnsafeMutablePointer<Memory>, index: mnimi) {
		self.obj = AEMemoryMirror(memory, index)
	}
	public init(_ obj: Obj) {
		self.obj = obj
	}
	deinit {
		AEObjWipe(&obj)
	}
	
	var def: Def { Def.def(obj: obj) ?? RealDef.def }
	public var display: String { def.format(obj: obj) }
//	var uiColor: UIColor { def.uiColor }

	static let i = Obje(AEObjComplex(0,1))
	static let e = Obje(AEObjReal(M_E))
	static let pi = Obje(AEObjReal(Double.pi))
	static let yes = Obje(AEObjReal(1))
	static let no = Obje(AEObjReal(0))
	static let chill = Obje(AEObjReal(0))
	static let eat = Obje(AEObjReal(1))
	static let flirt = Obje(AEObjReal(2))
	static let fight = Obje(AEObjReal(3))
	static let flee = Obje(AEObjReal(4))
	static let wander = Obje(AEObjReal(5))
}

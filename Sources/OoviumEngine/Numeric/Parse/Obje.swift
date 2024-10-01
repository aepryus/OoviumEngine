//
//  Obje.swift
//  Oovium
//
//  Created by Joe Charlier on 2/25/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import Aegean
import Foundation

public class Obje: CustomStringConvertible {
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
	
	public var def: Def { Def.def(obj: obj) ?? RealDef.def }
	public var display: String { def.format(obj: obj) }
    
    public var description: String { display }

	public static let i = Obje(AEObjComplex(0,1))
	public static let e = Obje(AEObjReal(M_E))
	public static let pi = Obje(AEObjReal(Double.pi))
	public static let yes = Obje(AEObjReal(1))
	public static let no = Obje(AEObjReal(0))
	public static let chill = Obje(AEObjReal(0))
	public static let eat = Obje(AEObjReal(1))
	public static let flirt = Obje(AEObjReal(2))
	public static let fight = Obje(AEObjReal(3))
	public static let flee = Obje(AEObjReal(4))
	public static let wander = Obje(AEObjReal(5))
}

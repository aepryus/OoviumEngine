//
//  Also.swift
//  Oovium
//
//  Created by Joe Charlier on 12/30/16.
//  Copyright © 2016 Aepryus Software. All rights reserved.
//

import Foundation

class Space {}

public final class Also: Aexel {
	@objc public var aetherPath: String = ""

	var spaceAether: (Space, Aether)? {
		return nil
//		guard let (space, aether) = Space.digest(aetherPath: aetherPath) else { return nil }
//		return (space, aether)
	}

	var aetherName: String {
		return ""
//		Space.split(aetherPath: aetherPath).1
	}
	var alsoAether: Aether? {
		return nil
//		spaceAether?.1
	}

	var functionCount: Int {
		return alsoAether?.functions(not: [aether]).count ?? 0
	}
	
// Aexel ===========================================================================================
//	override var towers: Set<Tower> {}
	
// Domain ==========================================================================================
	override public var properties: [String] {
		return super.properties + ["aetherPath"]
	}
}

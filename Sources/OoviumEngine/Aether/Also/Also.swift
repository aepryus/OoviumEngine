//
//  Also.swift
//  Oovium
//
//  Created by Joe Charlier on 12/30/16.
//  Copyright © 2016 Aepryus Software. All rights reserved.
//

import Foundation

public class Space {}

public final class Also: Aexel {
	@objc public var aetherPath: String = ""

	public var spaceAether: (Space, Aether)? {
		return nil
//		guard let (space, aether) = Space.digest(aetherPath: aetherPath) else { return nil }
//		return (space, aether)
	}

	public var aetherName: String {
		return ""
//		Space.split(aetherPath: aetherPath).1
	}
	public var alsoAether: Aether? {
		return nil
//		spaceAether?.1
	}

	public var functionCount: Int {
		return alsoAether?.functions(not: [aether]).count ?? 0
	}
	
// Aexel ===========================================================================================
//	override var towers: Set<Tower> {}
	
// Domain ==========================================================================================
	override public var properties: [String] {
		return super.properties + ["aetherPath"]
	}
}

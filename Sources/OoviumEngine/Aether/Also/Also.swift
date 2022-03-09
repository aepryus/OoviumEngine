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

// Aexel ===========================================================================================
//	override var towers: Set<Tower> {}
	
// Domain ==========================================================================================
	override public var properties: [String] {
		return super.properties + ["aetherPath"]
	}
}

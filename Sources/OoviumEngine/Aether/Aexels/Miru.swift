//
//  Miru.swift
//  Oovium
//
//  Created by Joe Charlier on 12/30/16.
//  Copyright © 2016 Aepryus Software. All rights reserved.
//

import Foundation

public final class Miru: Aexel {
	@objc public var gridID: Int = 0

// Aexel ===========================================================================================
	
// Domain ==========================================================================================
	override public var properties: [String] { super.properties + ["gridID"] }
}

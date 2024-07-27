//
//  Miru.swift
//  Oovium
//
//  Created by Joe Charlier on 12/30/16.
//  Copyright © 2016 Aepryus Software. All rights reserved.
//

/*
 *  Miru is intended to be a data visualizer that clips on to a GridBub.  I can be used to visualize
 *  the data within the GribBub in a way akin to Lotus Improv
 */

import Foundation

public final class Miru: Aexel {
	@objc public var gridID: Int = 0

// Aexel ===========================================================================================
	
// Domain ==========================================================================================
	override public var properties: [String] { super.properties + ["gridID"] }
}

//
//  Also.swift
//  Oovium
//
//  Created by Joe Charlier on 12/30/16.
//  Copyright © 2016 Aepryus Software. All rights reserved.
//

/*
 *  Also is for importing other Aethers into the current Aether.
 */

import Foundation

public final class Also: Aexel {
	@objc public var aetherPath: String = ""
    
// Domain ==========================================================================================
	override public var properties: [String] { super.properties + ["aetherPath"] }
}

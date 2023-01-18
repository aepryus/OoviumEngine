//
//  Type.swift
//  Oovium
//
//  Created by Joe Charlier on 12/30/16.
//  Copyright © 2016 Aepryus Software. All rights reserved.
//

import Foundation

public final class Type: Aexel {
	@objc public dynamic var color: OOColor = .black
	
	@objc public dynamic var fields: [Field] = []

// Domain ==========================================================================================
    override public var properties: [String] { super.properties + ["color"] }
	override public var children: [String] { super.children + ["fields"] }
}

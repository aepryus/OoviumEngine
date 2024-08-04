//
//  Type.swift
//  Oovium
//
//  Created by Joe Charlier on 12/30/16.
//  Copyright © 2016 Aepryus Software. All rights reserved.
//

/*
 *  Type is intended to be for the creation of custom Type Objects.  Field represents the
 *  properties of this custom Type.  Additionally methods will also be able to be defined.
 *  This is to be Oovium's 'class' concept.
 */

import Foundation

public final class Type: Aexel {
	@objc public dynamic var color: OOColor = .black
	
	@objc public dynamic var fields: [Field] = []
    
// Aexon ===========================================================================================
    override public func newNo(type: String) -> Int { fields.count + 1 }

// Domain ==========================================================================================
    override public var properties: [String] { super.properties + ["color"] }
	override public var children: [String] { super.children + ["fields"] }
}

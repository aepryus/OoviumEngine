//
//  State.swift
//  Oovium
//
//  Created by Joe Charlier on 12/30/16.
//  Copyright © 2016 Aepryus Software. All rights reserved.
//

import Acheron
import Foundation

public class State: Aexon {
//	@objc public var no: Int = 0
	@objc public var color: Int = 0
	
    public init(no: Int, color: Text.Color, automata: Automata) {
//		self.no = no
		self.color = color.rawValue
		super.init(parent: automata)
	}
	public required init(attributes: [String : Any], parent: Domain?) {
		super.init(attributes: attributes, parent: parent)
	}
	
// Domain ==========================================================================================
	public override var properties: [String] { super.properties + ["no", "color"] }
}

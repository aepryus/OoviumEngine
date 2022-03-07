//
//  Object.swift
//  Oovium
//
//  Created by Joe Charlier on 12/30/16.
//  Copyright © 2016 Aepryus Software. All rights reserved.
//

import Acheron
import Foundation

public final class Object: Aexel {
	@objc public var chain: Chain!
	@objc public var label: String = "" {
		didSet {
			if label.count > 0 { chain.label = label }
			else { chain.label = nil }
		}
	}
	
	var tower: Tower {
		return chain.tower
	}
	var token: VariableToken {
		return tower.variableToken
	}
	
// Inits ===========================================================================================
	public required init(no: Int, at: V2, aether: Aether) {
		chain = Chain()
		super.init(no: no, at: at, aether: aether)
	}
	public required init(attributes: [String:Any], parent: Domain?) {
		super.init(attributes: attributes, parent: parent)
	}
	
// Events ==========================================================================================
	override public func onLoad() {
		chain.tower = Tower(aether: aether, token: aether.variableToken(tag: "Ob_\(no)"), delegate: chain)
		name = chain.tower.name
		if label.count > 0 {
			chain.label = label
			token.label = label
		}
	}
	
// Aexel ===========================================================================================
	override var towers: Set<Tower> {
		return Set<Tower>([tower])
	}
	
// Domain ==========================================================================================
	override public var properties: [String] {
		return super.properties + ["chain", "label"]
	}
}

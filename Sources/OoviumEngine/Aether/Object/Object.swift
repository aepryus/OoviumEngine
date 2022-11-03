//
//  Object.swift
//  Oovium
//
//  Created by Joe Charlier on 12/30/16.
//  Copyright © 2016 Aepryus Software. All rights reserved.
//

import Acheron
import Foundation

public final class Object: Aexel, VariableTokenDelegate {
	@objc public var chain: Chain = Chain()
    @objc public var label: String = ""

    public var token: VariableToken { chain.tower.variableToken }
	
// Events ==========================================================================================
    override public func onLoad() {
        chain.tower = aether.createTower(tag: key, towerDelegate: chain, tokenDelegate: self)
    }
	
// Aexel ===========================================================================================
    public override var code: String { "Ob" }
    public override var towers: Set<Tower> { Set<Tower>([chain.tower]) }
	
// Domain ==========================================================================================
	override public var properties: [String] { super.properties + ["chain", "label"] }
    
// VariableTokenDelegate ===========================================================================
    public var alias: String? { label.count > 0 ? label : nil }
}

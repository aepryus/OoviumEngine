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
	@objc public var chain: Chain!
    @objc public var label: String = ""

//    public var token: VariableToken { aether.variableToken(tag: key) as! VariableToken }
    
// Inits ===========================================================================================
    public required init(at: V2, aether: Aether) {
        super.init(at: at, aether: aether)
        chain = Chain(key: TokenKey(code: .va, tag: key))
    }
    public required init(attributes: [String:Any], parent: Domain?) {
        super.init(attributes: attributes, parent: parent)
    }

// Events ==========================================================================================
//    override public func onLoad() {
//        print("Creating tower for [\(key)]")
//        chain.tower = aether.state.createTower(tag: key, towerDelegate: chain, tokenDelegate: self)
//    }
	
// Aexel ===========================================================================================
    public override var tokenKeys: Set<TokenKey> { Set<TokenKey>([chain.key!]) }
    public override var chains: [Chain] { [chain] }
    
// Aexon ===========================================================================================
    public override var code: String { "Ob" }

// Domain ==========================================================================================
	override public var properties: [String] { super.properties + ["chain", "label"] }
    
// VariableTokenDelegate ===========================================================================
    public var alias: String? { label.count > 0 ? label : nil }
}

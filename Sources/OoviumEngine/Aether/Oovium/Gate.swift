//
//  Gate.swift
//  Oovium
//
//  Created by Joe Charlier on 12/30/16.
//  Copyright © 2016 Aepryus Software. All rights reserved.
//

import Aegean
import Acheron
import Foundation

public class Gate: Aexel {
	@objc public var ifChain: Chain!
	@objc public var thenChain: Chain!
	@objc public var elseChain: Chain!
    
    public var ifTokenKey: TokenKey { TokenKey(code: .va, tag: "\(key).if") }
    public var thenTokenKey: TokenKey { TokenKey(code: .va, tag: "\(key).then") }
    public var elseTokenKey: TokenKey { TokenKey(code: .va, tag: "\(key).else") }
    public var tokenKey: TokenKey { TokenKey(code: .va, tag: key) }

// Inits ===========================================================================================
	public required init(at: V2, aether: Aether) {
		super.init(at: at, aether: aether)
        
        ifChain = Chain(key: ifTokenKey)
        thenChain = Chain(key: thenTokenKey)
        elseChain = Chain(key: elseTokenKey)
	}
	public required init(attributes: [String:Any], parent: Domain?) {
		super.init(attributes: attributes, parent: parent)
	}

// Aexon ===========================================================================================
    public override var code: String { "Gt" }
    public override var tokenKeys: [TokenKey] { [ifTokenKey, thenTokenKey, elseTokenKey, tokenKey] }
    public override func createCores() -> [Core] { [
        ChainCore(chain: ifChain),
        ChainCore(chain: elseChain),
        ChainCore(chain: thenChain),
        GateCore(gate: self)
    ] }

// Domain ==========================================================================================
    public override var properties: [String] { super.properties + ["ifChain", "thenChain", "elseChain"] }
}

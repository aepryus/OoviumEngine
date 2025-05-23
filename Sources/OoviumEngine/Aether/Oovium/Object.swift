//
//  Object.swift
//  Oovium
//
//  Created by Joe Charlier on 12/30/16.
//  Copyright © 2016 Aepryus Software. All rights reserved.
//

import Acheron
import Foundation

public class Object: Aexel, VariableTokenDelegate {
	@objc public var chain: Chain!
    @objc public var label: String = ""
    
    public var tokenKey: TokenKey { TokenKey(code: .va, tag: key) }
    
// Inits ===========================================================================================
    public required init(at: V2, aether: Aether) {
        super.init(at: at, aether: aether)
        chain = Chain(key: tokenKey)
    }
    public required init(attributes: [String:Any], parent: Domain?) {
        super.init(attributes: attributes, parent: parent)
    }

// Aexon ===========================================================================================
    public override var code: String { "Ob" }
    public override var tokenKeys: [TokenKey] { [tokenKey] }
    public override func createCores() -> [Core] { [ChainCore(chain: chain, variableTokenDelegate: self)] }
    public override var chains: [Chain] { [chain] }

// Domain ==========================================================================================
	public override var properties: [String] { super.properties + ["chain", "label"] }
    
// VariableTokenDelegate ===========================================================================
    public var alias: String? { label.count > 0 ? label : nil }
}

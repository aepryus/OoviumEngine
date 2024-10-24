//
//  Vertebra.swift
//  Oovium
//
//  Created by Joe Charlier on 12/30/16.
//  Copyright © 2016 Aepryus Software. All rights reserved.
//

import Acheron
import Foundation

public class Vertebra: Aexon, VariableTokenDelegate {
    @objc public dynamic var name: String = "" {
        didSet {
            if name == "" { name = oldValue }
            else { name = Aether.ensureUniquiness(name: name, names: tail.vertebras.filter({ $0 !== self }).map({ $0.name })) }
        }
    }
	@objc public dynamic var chain: Chain!

    public var tokenKey: TokenKey { TokenKey(code: .va, tag: fullKey) }
    var resultTokenKey: TokenKey { TokenKey(code: .va, tag: "\(fullKey).result") }
    
// Inits ===========================================================================================
    init(tail: Tail, name: String) {
		self.name = name
        super.init(parent: tail)
        chain = Chain(key: resultTokenKey)
	}
	required init(attributes: [String : Any], parent: Domain?) {
		super.init(attributes: attributes, parent: parent)
	}

	var tail: Tail { parent as! Tail }

// Aexon ===========================================================================================
    public override var code: String { "i" }
    public override var tokenKeys: [TokenKey] { [
        tokenKey,
        resultTokenKey
    ] }
    public override func createCores() -> [Core] { [
        ChainCore(chain: chain, fog: tail.mechlikeTokenKey),
        VertebraCore(vertebra: self)
    ] }

// Domain ==========================================================================================
	public override var properties: [String] { super.properties + ["name", "no", "chain"] }
	
// Core ===================================================================================
    func renderDisplay(tower: Tower) -> String { name }
    
// VariableTokenDelegate ===========================================================================
    public var alias: String? { name }
}

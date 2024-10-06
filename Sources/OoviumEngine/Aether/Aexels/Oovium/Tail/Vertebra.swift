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

//    var def: Def = RealDef.def

//    public lazy var tower: Tower = { tail.aether.state.createTower(tag: "\(tail.key).\(key)", towerDelegate: self, tokenDelegate: self) }()
    public lazy var tokenKey: TokenKey = TokenKey(code: .va, tag: fullKey)
    
    private func wire() {
//        chain.tower = tail.aether.state.createTower(tag: "\(tail.key).\(key).chain", towerDelegate: chain)
//        tower.web = tail.web
    }

// Inits ===========================================================================================
    init(tail: Tail, name: String) {
		self.name = name
        super.init(parent: tail)
        chain = Chain(key: TokenKey(code: .va, tag: "\(fullKey).result"))
	}
	required init(attributes: [String : Any], parent: Domain?) {
		super.init(attributes: attributes, parent: parent)
	}

	var tail: Tail { parent as! Tail }

// Aexon ===========================================================================================
    public override var code: String { "v" }
    public override var tokenKeys: [TokenKey] { [
        chain.key!,
        tokenKey
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

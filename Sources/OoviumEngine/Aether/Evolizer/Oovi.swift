//
//  Oovi.swift
//  Oovium
//
//  Created by Joe Charlier on 10/24/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import Aegean
import Acheron
import Foundation

public class Oovi: Aexel, VariableTokenDelegate {
	@objc public override var name: String {
		didSet { nameChanged() }
	}
    @objc public var color: Text.Color = Text.Color.white
	@objc public var stepChain: Chain!
	@objc public var amorousChain: Chain!

    public var speedTokenKey:     TokenKey { TokenKey(code: .va, tag: "\(key).speed") }
    public var energyTokenKey:    TokenKey { TokenKey(code: .va, tag: "\(key).energy") }
    public var visionTokenKey:    TokenKey { TokenKey(code: .va, tag: "\(key).vision") }
    public var attackTokenKey:    TokenKey { TokenKey(code: .va, tag: "\(key).attack") }
    public var armorTokenKey:     TokenKey { TokenKey(code: .va, tag: "\(key).armor") }
    public var healthTokenKey:    TokenKey { TokenKey(code: .va, tag: "\(key).health") }

    public var fruitsTokenKey:    TokenKey { TokenKey(code: .va, tag: "\(key).fruits") }
    public var matesTokenKey:     TokenKey { TokenKey(code: .va, tag: "\(key).mates") }
    public var friendsTokenKey:   TokenKey { TokenKey(code: .va, tag: "\(key).friends") }
    public var enemiesTokenKey:   TokenKey { TokenKey(code: .va, tag: "\(key).enemies") }

    public var capacityTokenKey:  TokenKey { TokenKey(code: .va, tag: "\(key).capacity") }
    public var remainingTokenKey: TokenKey { TokenKey(code: .va, tag: "\(key).remaining") }
    public var usedTokenKey:      TokenKey { TokenKey(code: .va, tag: "\(key).used") }
    public var hungerTokenKey:    TokenKey { TokenKey(code: .va, tag: "\(key).hunger") }

    public var genderTokenKey:    TokenKey { TokenKey(code: .va, tag: "\(key).gender") }
    public var pregnantTokenKey:  TokenKey { TokenKey(code: .va, tag: "\(key).pregnant") }
    public var damageTokenKey:    TokenKey { TokenKey(code: .va, tag: "\(key).damage") }

    public var paramTokenKeys: [TokenKey] { [
        speedTokenKey, energyTokenKey, visionTokenKey, attackTokenKey, armorTokenKey, healthTokenKey,
        fruitsTokenKey, matesTokenKey, friendsTokenKey, enemiesTokenKey,
        capacityTokenKey, remainingTokenKey, usedTokenKey, hungerTokenKey,
        genderTokenKey, pregnantTokenKey, damageTokenKey
    ] }

    public var variableTokenKey: TokenKey { TokenKey(code: .va, tag: key) }
    public var mechlikeTokenKey: TokenKey { TokenKey(code: .ml, tag: key) }

    private static let paramNames: [String] = [
        "speed", "energy", "vision", "attack", "armor", "health",
        "fruits", "mates", "friends", "enemies",
        "capacity", "remaining", "used", "hunger",
        "gender", "pregnant", "damage"
    ]

    public required init(at: V2, aether: Aether) {
        super.init(at:at, aether: aether)
        amorousChain = Chain(key: TokenKey(code: .va, tag: "\(key).amorous"))
        stepChain = Chain(key: TokenKey(code: .va, tag: "\(key).step"))
    }
	public required init(attributes: [String:Any], parent: Domain?) {
		super.init(attributes: attributes, parent: parent)
	}

	private func nameChanged() {
		aether.name = name
	}

    public func compileRecipies() {}

// Aexon ===========================================================================================
    public override var code: String { "Ov" }
    public override var tokenKeys: [TokenKey] {
        paramTokenKeys + [
            amorousChain.key!,
            stepChain.key!,
            variableTokenKey,
            mechlikeTokenKey
        ]
    }
    public override func createCores() -> [Core] {
        var cores: [Core] = []
        for (i, tokenKey) in paramTokenKeys.enumerated() {
            cores.append(ParameterCore(parameter: StaticParameter(
                tokenKey: tokenKey,
                fogKey: mechlikeTokenKey,
                name: Oovi.paramNames[i]
            )))
        }
        cores.append(ChainCore(chain: amorousChain, fog: mechlikeTokenKey))
        cores.append(ChainCore(chain: stepChain,    fog: mechlikeTokenKey))
        cores.append(OoviCore(oovi: self))
        return cores
    }
    public override var chains: [Chain] { [amorousChain, stepChain] }

// Domain ==========================================================================================
    override open var properties: [String] {
        return super.properties + ["color", "stepChain", "amorousChain"]
    }

// VariableTokenDelegate ===========================================================================
    var alias: String? { nil }
}

//
//  Cron.swift
//  Oovium
//
//  Created by Joe Charlier on 12/30/16.
//  Copyright © 2016 Aepryus Software. All rights reserved.
//

import Aegean
import Acheron
import Foundation

@objc public enum OOEndMode: Int {
	case stop, `repeat`, bounce, endless, `while`
}

public class Cron: Aexel {
	@objc public var startChain: Chain!
	@objc public var stopChain: Chain!
	@objc public var stepsChain: Chain!
	@objc public var rateChain: Chain!
	@objc public var deltaChain: Chain!
	@objc public var whileChain: Chain!
	@objc public var endMode: OOEndMode = .stop
	@objc public var exposed: Bool = true


    var startTokenKey: TokenKey { TokenKey(code: .va, tag: "\(key).start") }
    var stopTokenKey: TokenKey { TokenKey(code: .va, tag: "\(key).stop") }
    var stepsTokenKey: TokenKey { TokenKey(code: .va, tag: "\(key).steps") }
    var rateTokenKey: TokenKey { TokenKey(code: .va, tag: "\(key).rate") }
    var deltaTokenKey: TokenKey { TokenKey(code: .va, tag: "\(key).delta") }
    var whileTokenKey: TokenKey { TokenKey(code: .va, tag: "\(key).while") }
    public var tokenKey: TokenKey { TokenKey(code: .va, tag: key) }

// Inits ===========================================================================================
	public required init(at: V2, aether: Aether) {
		super.init(at: at, aether: aether)

        startChain = Chain(key: startTokenKey)
        stopChain = Chain(key: stopTokenKey)
        stepsChain = Chain(key: stepsTokenKey)
        rateChain = Chain(key: rateTokenKey)
        deltaChain = Chain(key: deltaTokenKey)
        whileChain = Chain(key: whileTokenKey)
	}
	public required init(attributes: [String:Any], parent: Domain?) {
		super.init(attributes: attributes, parent: parent)
	}
	
// Aexon ===========================================================================================
    public override var code: String { "Cr" }
    public override var tokenKeys: [TokenKey] { [startTokenKey, stopTokenKey, stepsTokenKey, rateTokenKey, deltaTokenKey, whileTokenKey, tokenKey] }
    public override func createCores() -> [Core] { [
        ChainCore(chain: startChain),
        ChainCore(chain: stopChain),
        ChainCore(chain: stepsChain),
        ChainCore(chain: rateChain),
        ChainCore(chain: deltaChain),
        ChainCore(chain: whileChain),
        CronCore(cron: self)
    ] }

// Domain ==========================================================================================
	public override var properties: [String] { super.properties + ["startChain", "stopChain", "stepsChain", "rateChain", "deltaChain", "whileChain", "endMode", "exposed"] }	
}

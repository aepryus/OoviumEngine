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

//    public lazy var tower: Tower = aether.state.createTower(tag: key, towerDelegate: self)
//    public var token: VariableToken { tower.variableToken }
    public lazy var tokenKey: TokenKey = TokenKey(code: .va, tag: fullKey)

//	public var startTower: Tower { startChain.tower }
//	public var stopTower: Tower { stopChain.tower }
//	public var stepsTower: Tower { stepsChain.tower }
//	public var rateTower: Tower { rateChain.tower }
//	public var deltaTower: Tower { deltaChain.tower }
//	public var whileTower: Tower { whileChain.tower }
	
// Inits ===========================================================================================
	public required init(at: V2, aether: Aether) {
		super.init(at: at, aether: aether)
		onLoad()
	}
	public required init(attributes: [String:Any], parent: Domain?) {
		super.init(attributes: attributes, parent: parent)
	}
	
// Aexel ===========================================================================================
    override public func createCores() -> [Core] { [
        ChainCore(chain: startChain),
        ChainCore(chain: stopChain),
        ChainCore(chain: stepsChain),
        ChainCore(chain: rateChain),
        ChainCore(chain: deltaChain),
        ChainCore(chain: whileChain),
        CronCore(cron: self)
    ] }

// Aexon ===========================================================================================
    public override var code: String { "Cr" }

// Domain ==========================================================================================
	public override var properties: [String] { super.properties + ["startChain", "stopChain", "stepsChain", "rateChain", "deltaChain", "whileChain", "endMode", "exposed"] }	
}

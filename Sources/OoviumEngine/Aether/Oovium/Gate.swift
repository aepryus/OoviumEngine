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
    
    public var resultKey: TokenKey!
	
//	public var ifTower: Tower { ifChain.tower }
//	public var thenTower: Tower { thenChain.tower }
//	public var elseTower: Tower { elseChain.tower }
//    public lazy var resultTower: Tower = aether.state.createTower(tag: key, towerDelegate: self)
	
//    public var token: VariableToken { resultTower.variableToken }

// Inits ===========================================================================================
	public required init(at: V2, aether: Aether) {
		super.init(at: at, aether: aether)
        
        ifChain = Chain(key: TokenKey(code: .va, tag: "\(key).if"))
        thenChain = Chain(key: TokenKey(code: .va, tag: "\(key).then"))
        elseChain = Chain(key: TokenKey(code: .va, tag: "\(key).else"))
        resultKey = TokenKey(code: .va, tag: key)
	}
	public required init(attributes: [String:Any], parent: Domain?) {
		super.init(attributes: attributes, parent: parent)
        resultKey = TokenKey(code: .va, tag: key)
	}

// Events ==========================================================================================
	public override func onLoaded() {
//        ifChain.tower = aether.state.createTower(tag: "\(key).if", towerDelegate: ifChain)
//        thenChain.tower = aether.state.createTower(tag: "\(key).then", towerDelegate: thenChain)
//        elseChain.tower = aether.state.createTower(tag: "\(key).else", towerDelegate: elseChain)

//		ifTower.gateTo = resultTower
//		ifTower.thenTo = thenTower
//		ifTower.elseTo = elseTower
//		thenTower.gate = ifTower
//		elseTower.gate = ifTower
//		
//		let funnel = Funnel(options: [thenTower, elseTower], spout: resultTower)
//		thenTower.funnel = funnel
//		elseTower.funnel = funnel
	}
	public override func onAdded() {
//		resultTower.buildStream()
	}
	
// Aexon ===========================================================================================
    public override var code: String { "Gt" }
    public override var tokenKeys: [TokenKey] { [ifChain.key!, elseChain.key!, thenChain.key!, resultKey] }
    public override func createCores() -> [Core] { [
        ChainCore(chain: ifChain),
        ChainCore(chain: elseChain),
        ChainCore(chain: thenChain),
        GateCore(gate: self)
    ] }

// Domain ==========================================================================================
    public override var properties: [String] { super.properties + ["ifChain", "thenChain", "elseChain"] }
}

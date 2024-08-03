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

public final class Gate: Aexel, TowerDelegate {
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
	override public func onLoaded() {
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
	override public func onAdded() {
//		resultTower.buildStream()
	}
	
// Aexel ===========================================================================================
    public override var code: String { "Gt" }
//	public var towers: Set<Tower> { Set<Tower>([ifTower, thenTower, elseTower, resultTower]) }
    public override var chains: [Chain] { [ifChain, thenChain, elseChain] }
	
// Domain ==========================================================================================
    override public var properties: [String] { super.properties + ["ifChain", "thenChain", "elseChain"] }

// TowerDelegate ===================================================================================
	func buildUpstream(tower: Tower) {
//		ifTower.attach(tower)
//		thenTower.attach(tower)
//		elseTower.attach(tower)
	}
	func renderDisplay(tower: Tower) -> String { "if" }
    func renderTask(tower: Tower) -> UnsafeMutablePointer<Task>? {
//		let resultName = resultTower.variableToken.tag
//		let task: UnsafeMutablePointer<Task> = AETaskCreateFork(ifTower.index, thenTower.index, elseTower.index, resultTower.index)
//		AETaskSetLabels(task, resultName.toInt8(), "\(resultName) = ~".toInt8())
//        return task
        nil
	}
	func taskCompleted(tower: Tower, askedBy: Tower) -> Bool {
		AEMemoryLoaded(tower.memory, tower.index) != 0
	}
	func taskBlocked(tower: Tower) -> Bool {
//		[ifTower,thenTower,elseTower].contains {$0.variableToken.status != .ok}
        false
	}
	func resetTask(tower: Tower) {
		AEMemoryUnfix(tower.memory, tower.index)
	}
	func executeTask(tower: Tower) {
		AETaskExecute(tower.task, tower.memory)
		AEMemoryFix(tower.memory, tower.index)
//		tower.variableToken.label = Oovium.format(value: tower.value)
	}
}

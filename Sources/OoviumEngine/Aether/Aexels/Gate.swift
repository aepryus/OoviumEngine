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
	
	public var ifTower: Tower { ifChain.tower }
	public var thenTower: Tower { thenChain.tower }
	public var elseTower: Tower { elseChain.tower }
    public lazy var resultTower: Tower = aether.createTower(tag: key, towerDelegate: self)
	
	public var token: Token {
		return resultTower.variableToken
	}

// Inits ===========================================================================================
	public required init(no: Int, at: V2, aether: Aether) {
		ifChain = Chain()
		thenChain = Chain()
		elseChain = Chain()

		super.init(no: no, at: at, aether: aether)
	}
	public required init(attributes: [String:Any], parent: Domain?) {
		super.init(attributes: attributes, parent: parent)
	}

// Events ==========================================================================================
	override public func onLoaded() {
        ifChain.tower = aether.createTower(tag: "\(key).if", towerDelegate: ifChain)
        thenChain.tower = aether.createTower(tag: "\(key).then", towerDelegate: thenChain)
        elseChain.tower = aether.createTower(tag: "\(key).else", towerDelegate: elseChain)

		ifTower.gateTo = resultTower
		ifTower.thenTo = thenTower
		ifTower.elseTo = elseTower
		thenTower.gate = ifTower
		elseTower.gate = ifTower
		
		let funnel = Funnel(options: [thenTower, elseTower], spout: resultTower)
		thenTower.funnel = funnel
		elseTower.funnel = funnel
	}
	override public func onAdded() {
		resultTower.buildStream()
	}
	
// Aexel ===========================================================================================
    public override var code: String { "Gt" }
	public override var towers: Set<Tower> { Set<Tower>([ifTower, thenTower, elseTower, resultTower]) }
	
// Domain ==========================================================================================
    override public var properties: [String] { super.properties + ["ifChain", "thenChain", "elseChain"] }

// TowerDelegate ===================================================================================
	func buildUpstream(tower: Tower) {
		ifTower.attach(tower)
		thenTower.attach(tower)
		elseTower.attach(tower)
	}
	func renderDisplay(tower: Tower) -> String {
		return "if"
	}
	func buildWorker(tower: Tower) {
		let resultName = resultTower.variableToken.tag
		let task: UnsafeMutablePointer<Task> = AETaskCreateFork(ifTower.index, thenTower.index, elseTower.index, resultTower.index)
		AETaskSetLabels(task, resultName.toInt8(), "\(resultName) = ~".toInt8())
		tower.task = task
	}
	func workerCompleted(tower: Tower, askedBy: Tower) -> Bool {
		return AEMemoryLoaded(tower.memory, tower.index) != 0
	}
	func workerBlocked(tower: Tower) -> Bool {
		return [ifTower,thenTower,elseTower].contains {$0.variableToken.status != .ok}
	}
	func resetWorker(tower: Tower) {
		AEMemoryUnfix(tower.memory, tower.index)
	}
	func executeWorker(tower: Tower) {
		AETaskExecute(tower.task, tower.memory)
		AEMemoryFix(tower.memory, tower.index)
//		tower.variableToken.label = Oovium.format(value: tower.value)
	}
}

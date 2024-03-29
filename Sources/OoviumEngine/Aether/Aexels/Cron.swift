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

public final class Cron: Aexel, TowerDelegate {
	@objc public var startChain: Chain = Chain()
	@objc public var stopChain: Chain = Chain()
	@objc public var stepsChain: Chain = Chain()
	@objc public var rateChain: Chain = Chain()
	@objc public var deltaChain: Chain = Chain()
	@objc public var whileChain: Chain = Chain()
	@objc public var endMode: OOEndMode = .stop
	@objc public var exposed: Bool = true

    public lazy var tower: Tower = aether.createTower(tag: key, towerDelegate: self)
    public var token: Token { tower.variableToken }

	public var startTower: Tower { startChain.tower }
	public var stopTower: Tower { stopChain.tower }
	public var stepsTower: Tower { stepsChain.tower }
	public var rateTower: Tower { rateChain.tower }
	public var deltaTower: Tower { deltaChain.tower }
	public var whileTower: Tower { whileChain.tower }
	
	public var t: Double = 0
	public var dt: Double = 1
	public var sealed: Bool = true
	
	public func reset() {
		if endMode == .stop || endMode == .repeat || endMode == .bounce {
			dt = (stopTower.value - startTower.value)/(stepsTower.value-1)
		} else {
			dt = deltaTower.value
		}
		t = startTower.value
		sealed = true
	}
	public func increment() -> Bool {
		if sealed {
			sealed = false
		} else if (endMode == .stop && t+dt > stopTower.value) || (endMode == .while && whileTower.value == 0) {
			t = startTower.value
		} else {
			t += dt
		}
		tower.trigger()
		switch endMode {
			case .stop:
				if t+dt > stopTower.value { return true }
			case .repeat:
				if t+dt > stopTower.value {
					t = startTower.value
					sealed = true
					return false
				}
			case .bounce:
				if t+dt > stopTower.value || t+dt < startTower.value {dt = -dt}
			case .endless: break;
			case .while:
				if whileTower.value == 0 {return true}
		}
		return false
	}

// Inits ===========================================================================================
	public required init(no: Int, at: V2, aether: Aether) {
		super.init(no: no, at: at, aether: aether)
		onLoad()
	}
	public required init(attributes: [String:Any], parent: Domain?) {
		super.init(attributes: attributes, parent: parent)
	}
	
// Events ==========================================================================================
	override public func onLoad() {
        startChain.tower = aether.createTower(tag: "\(key).start", towerDelegate: startChain)
		stopChain.tower = aether.createTower(tag: "\(key).stop", towerDelegate: stopChain)
		stepsChain.tower = aether.createTower(tag: "\(key).steps", towerDelegate: stepsChain)
		rateChain.tower = aether.createTower(tag: "\(key).rate", towerDelegate: rateChain)
		deltaChain.tower = aether.createTower(tag: "\(key).delta", towerDelegate: deltaChain)
		whileChain.tower = aether.createTower(tag: "\(key).while", towerDelegate: whileChain)
	}
	
// Aexel ===========================================================================================
    public override var code: String { "Cr" }
	public override var towers: Set<Tower> { Set<Tower>([startTower, stopTower, stepsTower, rateTower, deltaTower, whileTower, tower]) }
	
// Domain ==========================================================================================
	override public var properties: [String] { super.properties + ["startChain", "stopChain", "stepsChain", "rateChain", "deltaChain", "whileChain", "endMode", "exposed"] }
	
// TowerDelegate ===================================================================================
	func renderDisplay(tower: Tower) -> String {
		return tower.obje.display
	}
	func workerCompleted(tower: Tower, askedBy: Tower) -> Bool {
		return AEMemoryLoaded(tower.memory, tower.index) != 0
	}
	func resetWorker(tower: Tower) {
		AEMemoryUnfix(tower.memory, tower.index)
	}
	func executeWorker(tower: Tower) {
		AEMemorySetValue(tower.memory, tower.index, t)
		AEMemoryFix(tower.memory, tower.index)
//		tower.variableToken.value = tower.obje.display
	}
}

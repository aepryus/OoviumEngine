//
//  Auto.swift
//  Oovium
//
//  Created by Joe Charlier on 12/30/16.
//  Copyright © 2016 Aepryus Software. All rights reserved.
//

import Aegean
import Acheron
import Foundation

public final class Auto: Aexel, TowerDelegate {
	@objc public var statesChain: Chain!
	@objc public var resultChain: Chain!
	
	@objc public var states: [State] = []
	
	public var statesTower: Tower {
		return statesChain.tower
	}
	public var resultTower: Tower {
		return resultChain.tower
	}
	public var spaceTowers: Set<Tower> = Set<Tower>()
	
	var web: AnyObject {return self}

// Inits ===========================================================================================
	public required init(no: Int, at: V2, aether: Aether) {
		statesChain = Chain()
		resultChain = Chain()
		
		super.init(no: no, at:at, aether: aether)

		add(state: State(no: 0, color: .clear))
		add(state: State(no: 1, color: .lavender))
	}
	public required init(attributes: [String:Any], parent: Domain?) {
		super.init(attributes: attributes, parent: parent)
	}
	
	private func buildSpaceTowers(no: Int) {
		spaceTowers.insert(Tower(aether: aether, token: aether.variableToken(tag: "Auto\(no).A", label: "A"), delegate: self))
		spaceTowers.insert(Tower(aether: aether, token: aether.variableToken(tag: "Auto\(no).B", label: "B"), delegate: self))
		spaceTowers.insert(Tower(aether: aether, token: aether.variableToken(tag: "Auto\(no).C", label: "C"), delegate: self))
		spaceTowers.insert(Tower(aether: aether, token: aether.variableToken(tag: "Auto\(no).D", label: "D"), delegate: self))
		spaceTowers.insert(Tower(aether: aether, token: aether.variableToken(tag: "Auto\(no).E", label: "E"), delegate: self))
		spaceTowers.insert(Tower(aether: aether, token: aether.variableToken(tag: "Auto\(no).F", label: "F"), delegate: self))
		spaceTowers.insert(Tower(aether: aether, token: aether.variableToken(tag: "Auto\(no).G", label: "G"), delegate: self))
		spaceTowers.insert(Tower(aether: aether, token: aether.variableToken(tag: "Auto\(no).H", label: "H"), delegate: self))
		spaceTowers.insert(Tower(aether: aether, token: aether.variableToken(tag: "Auto\(no).Self", label: "Self"), delegate: self))
		
		for tower in spaceTowers {
			tower.web = web
		}
	}
	
	public func foreshadow(_ memory: UnsafeMutablePointer<Memory>) {
		AEMemorySetValue(memory, AEMemoryIndexForName(memory, "Auto\(no).A".toInt8()), 0)
		AEMemorySetValue(memory, AEMemoryIndexForName(memory, "Auto\(no).B".toInt8()), 0)
		AEMemorySetValue(memory, AEMemoryIndexForName(memory, "Auto\(no).C".toInt8()), 0)
		AEMemorySetValue(memory, AEMemoryIndexForName(memory, "Auto\(no).D".toInt8()), 0)
		AEMemorySetValue(memory, AEMemoryIndexForName(memory, "Auto\(no).E".toInt8()), 0)
		AEMemorySetValue(memory, AEMemoryIndexForName(memory, "Auto\(no).F".toInt8()), 0)
		AEMemorySetValue(memory, AEMemoryIndexForName(memory, "Auto\(no).G".toInt8()), 0)
		AEMemorySetValue(memory, AEMemoryIndexForName(memory, "Auto\(no).H".toInt8()), 0)
		AEMemorySetValue(memory, AEMemoryIndexForName(memory, "Auto\(no).Self".toInt8()), 0)
	}
	
	public func add(state: State) {
		add(state)
		states.append(state)
	}
	public func addState() {
		let state = State(no: states.count, color: OOColor(rawValue: states.count)!)
		add(state: state)
	}
	
	public func buildStates() {
		let n = min(max(Int(statesTower.value), 2), 32)
		guard n != states.count else { return }

		if n < states.count {
			for _ in n..<states.count {
				states.removeLast()
			}
		} else {
			for _ in states.count..<n {
				addState()
			}
		}
	}
	
// Events ==========================================================================================
	override public func onLoad() {
		statesChain.tower = Tower(aether: aether, token: aether.variableToken(tag: "AtS_\(no)"), delegate: statesChain)
		resultChain.tower = Tower(aether: aether, token: aether.variableToken(tag: "AtR_\(no)"), delegate: resultChain)
		
		statesTower.tailForWeb = web
		resultTower.tailForWeb = web
		
		buildSpaceTowers(no: no)
	}
	
// Aexel ===========================================================================================
	public override var towers: Set<Tower> {
		return spaceTowers.union([statesTower, resultTower])
	}
	
// Domain ==========================================================================================
	override public var properties: [String] {
		return super.properties + ["statesChain", "resultChain"]
	}
	override public var children: [String] {
		return super.children + ["states"]
	}
}

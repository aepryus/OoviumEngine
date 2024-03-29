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
	
	public var statesTower: Tower { statesChain.tower }
	public var resultTower: Tower { resultChain.tower }
	public var spaceTowers: [Tower] = []
	
	var web: AnyObject { self }
    
    private let tokenDelegates: [StaticVariableTokenDelegate] = {[
        StaticVariableTokenDelegate("A"),
        StaticVariableTokenDelegate("B"),
        StaticVariableTokenDelegate("C"),
        StaticVariableTokenDelegate("D"),
        StaticVariableTokenDelegate("E"),
        StaticVariableTokenDelegate("F"),
        StaticVariableTokenDelegate("G"),
        StaticVariableTokenDelegate("H"),
        StaticVariableTokenDelegate("Self"),
    ]}()
    
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
        spaceTowers.append(aether.createTower(tag: "\(key).A", towerDelegate: self, tokenDelegate: tokenDelegates[0]))
        spaceTowers.append(aether.createTower(tag: "\(key).B", towerDelegate: self, tokenDelegate: tokenDelegates[1]))
        spaceTowers.append(aether.createTower(tag: "\(key).C", towerDelegate: self, tokenDelegate: tokenDelegates[2]))
        spaceTowers.append(aether.createTower(tag: "\(key).D", towerDelegate: self, tokenDelegate: tokenDelegates[3]))
        spaceTowers.append(aether.createTower(tag: "\(key).E", towerDelegate: self, tokenDelegate: tokenDelegates[4]))
        spaceTowers.append(aether.createTower(tag: "\(key).F", towerDelegate: self, tokenDelegate: tokenDelegates[5]))
        spaceTowers.append(aether.createTower(tag: "\(key).G", towerDelegate: self, tokenDelegate: tokenDelegates[6]))
        spaceTowers.append(aether.createTower(tag: "\(key).H", towerDelegate: self, tokenDelegate: tokenDelegates[7]))
        spaceTowers.append(aether.createTower(tag: "\(key).Self", towerDelegate: self, tokenDelegate: tokenDelegates[8]))

        spaceTowers.forEach { $0.web = web }
	}
	
	public func foreshadow(_ memory: UnsafeMutablePointer<Memory>) {
		AEMemorySetValue(memory, AEMemoryIndexForName(memory, "Au\(no).A".toInt8()), 0)
		AEMemorySetValue(memory, AEMemoryIndexForName(memory, "Au\(no).B".toInt8()), 0)
		AEMemorySetValue(memory, AEMemoryIndexForName(memory, "Au\(no).C".toInt8()), 0)
		AEMemorySetValue(memory, AEMemoryIndexForName(memory, "Au\(no).D".toInt8()), 0)
		AEMemorySetValue(memory, AEMemoryIndexForName(memory, "Au\(no).E".toInt8()), 0)
		AEMemorySetValue(memory, AEMemoryIndexForName(memory, "Au\(no).F".toInt8()), 0)
		AEMemorySetValue(memory, AEMemoryIndexForName(memory, "Au\(no).G".toInt8()), 0)
		AEMemorySetValue(memory, AEMemoryIndexForName(memory, "Au\(no).H".toInt8()), 0)
		AEMemorySetValue(memory, AEMemoryIndexForName(memory, "Au\(no).Self".toInt8()), 0)
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

		if n < states.count { for _ in n..<states.count { states.removeLast() } }
        else { for _ in states.count..<n { addState() } }
	}
	
// Events ==========================================================================================
	override public func onLoad() {
        statesChain.tower = aether.createTower(tag: "\(key).states", towerDelegate: statesChain)
        resultChain.tower = aether.createTower(tag: "\(key).result", towerDelegate: resultChain)
		
		statesTower.tailForWeb = web
		resultTower.tailForWeb = web
		
		buildSpaceTowers(no: no)
	}
	
// Aexel ===========================================================================================
    public override var code: String { "Au" }
    public override var towers: Set<Tower> {
        var towers = Set<Tower>()
        spaceTowers.forEach { towers.insert($0) }
        return towers.union([resultTower, statesTower])
    }
	
// Domain ==========================================================================================
    override public var properties: [String] { super.properties + ["statesChain", "resultChain"] }
    override public var children: [String] { super.children + ["states"] }
}

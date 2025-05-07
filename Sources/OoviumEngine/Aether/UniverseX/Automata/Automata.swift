//
//  Automata.swift
//  Oovium
//
//  Created by Joe Charlier on 12/30/16.
//  Copyright © 2016 Aepryus Software. All rights reserved.
//

import Aegean
import Acheron
import Foundation

public class Automata: Aexel, VariableTokenDelegate {
	@objc public var statesChain: Chain!
	@objc public var resultChain: Chain!
	
	@objc public var states: [State] = []
	
    public var selfTokenKey: TokenKey { TokenKey(code: .va, tag: "\(key).Self") }
    public var aTokenKey: TokenKey { TokenKey(code: .va, tag: "\(key).A") }
    public var bTokenKey: TokenKey { TokenKey(code: .va, tag: "\(key).B") }
    public var cTokenKey: TokenKey { TokenKey(code: .va, tag: "\(key).C") }
    public var dTokenKey: TokenKey { TokenKey(code: .va, tag: "\(key).D") }
    public var eTokenKey: TokenKey { TokenKey(code: .va, tag: "\(key).E") }
    public var fTokenKey: TokenKey { TokenKey(code: .va, tag: "\(key).F") }
    public var gTokenKey: TokenKey { TokenKey(code: .va, tag: "\(key).G") }
    public var hTokenKey: TokenKey { TokenKey(code: .va, tag: "\(key).H") }
    
    public var statesTokenKey: TokenKey { TokenKey(code: .va, tag: "\(key).states") }
    public var resultTokenKey: TokenKey { TokenKey(code: .va, tag: "\(key).result") }

    public var mechlikeTokenKey: TokenKey { TokenKey(code: .ml, tag: key) }
    public var variableTokenKey: TokenKey { TokenKey(code: .va, tag: key) }

    private let tokenDelegates: [StaticVariableTokenDelegate] = {[
        StaticVariableTokenDelegate("Self"),
        StaticVariableTokenDelegate("A"),
        StaticVariableTokenDelegate("B"),
        StaticVariableTokenDelegate("C"),
        StaticVariableTokenDelegate("D"),
        StaticVariableTokenDelegate("E"),
        StaticVariableTokenDelegate("F"),
        StaticVariableTokenDelegate("G"),
        StaticVariableTokenDelegate("H")
    ]}()
    
// Inits ===========================================================================================
	public required init(at: V2, aether: Aether) {
		super.init(at:at, aether: aether)
        
        statesChain = Chain(key: statesTokenKey)
        resultChain = Chain(key: resultTokenKey)

		add(state: State(no: 0, color: .clear, automata: self))
		add(state: State(no: 1, color: .lavender, automata: self))
	}
	public required init(attributes: [String:Any], parent: Domain?) {
		super.init(attributes: attributes, parent: parent)
	}
	
	public func foreshadow(_ memory: UnsafeMutablePointer<Memory>) {
        AEMemorySetValue(memory, AEMemoryIndexForName(memory, "Au\(no).Self".toInt8()), 0)
		AEMemorySetValue(memory, AEMemoryIndexForName(memory, "Au\(no).A".toInt8()), 0)
		AEMemorySetValue(memory, AEMemoryIndexForName(memory, "Au\(no).B".toInt8()), 0)
		AEMemorySetValue(memory, AEMemoryIndexForName(memory, "Au\(no).C".toInt8()), 0)
		AEMemorySetValue(memory, AEMemoryIndexForName(memory, "Au\(no).D".toInt8()), 0)
		AEMemorySetValue(memory, AEMemoryIndexForName(memory, "Au\(no).E".toInt8()), 0)
		AEMemorySetValue(memory, AEMemoryIndexForName(memory, "Au\(no).F".toInt8()), 0)
		AEMemorySetValue(memory, AEMemoryIndexForName(memory, "Au\(no).G".toInt8()), 0)
		AEMemorySetValue(memory, AEMemoryIndexForName(memory, "Au\(no).H".toInt8()), 0)
	}
	
	public func add(state: State) {
		add(state)
		states.append(state)
	}
	public func addState() {
		let state = State(no: states.count, color: Text.Color(rawValue: states.count)!, automata: self)
		add(state: state)
	}
    public func buildStates() {
        let n = 2
        guard n != states.count else { return }

        if n < states.count { for _ in n..<states.count { states.removeLast() } }
        else { for _ in states.count..<n { addState() } }
    }
	
// Aexon ===========================================================================================
    public override var code: String { "Au" }
    public override var tokenKeys: [TokenKey] { [
        selfTokenKey,
        aTokenKey,
        bTokenKey,
        cTokenKey,
        dTokenKey,
        eTokenKey,
        fTokenKey,
        gTokenKey,
        hTokenKey,
        statesTokenKey,
        resultTokenKey,
        mechlikeTokenKey,
        variableTokenKey
    ] }
    public override func createCores() -> [Core] { [
        ParameterCore(parameter: StaticParameter(tokenKey: selfTokenKey, fogKey: mechlikeTokenKey, name: "Self")),
        ParameterCore(parameter: StaticParameter(tokenKey: aTokenKey, fogKey: mechlikeTokenKey, name: "A")),
        ParameterCore(parameter: StaticParameter(tokenKey: bTokenKey, fogKey: mechlikeTokenKey, name: "B")),
        ParameterCore(parameter: StaticParameter(tokenKey: cTokenKey, fogKey: mechlikeTokenKey, name: "C")),
        ParameterCore(parameter: StaticParameter(tokenKey: dTokenKey, fogKey: mechlikeTokenKey, name: "D")),
        ParameterCore(parameter: StaticParameter(tokenKey: eTokenKey, fogKey: mechlikeTokenKey, name: "E")),
        ParameterCore(parameter: StaticParameter(tokenKey: fTokenKey, fogKey: mechlikeTokenKey, name: "F")),
        ParameterCore(parameter: StaticParameter(tokenKey: gTokenKey, fogKey: mechlikeTokenKey, name: "G")),
        ParameterCore(parameter: StaticParameter(tokenKey: hTokenKey, fogKey: mechlikeTokenKey, name: "H")),
        ChainCore(chain: statesChain),
        ChainCore(chain: resultChain, fog: mechlikeTokenKey),
        AutomataCore(automata: self)
    ] }
    public override var chains: [Chain] { [statesChain, resultChain] }

// Domain ==========================================================================================
    public override var properties: [String] { super.properties + ["statesChain", "resultChain"] }
    public override var children: [String] { super.children + ["states"] }
    
// VariableTokenDelegate ===========================================================================
    var alias: String? { nil }
}

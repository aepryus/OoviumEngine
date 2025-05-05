//
//  Tail.swift
//  Oovium
//
//  Created by Joe Charlier on 12/30/16.
//  Copyright © 2016 Aepryus Software. All rights reserved.
//

import Aegean
import Acheron
import Foundation

public class Tail: Aexel, Mechlike, VariableTokenDelegate {
	@objc public var whileChain: Chain!
	@objc public var resultChain: Chain!
	@objc public var vertebras: [Vertebra] = []	
	
	public var tower: Tower!

    public var mechlikeTokenKey: TokenKey { TokenKey(code: .ml, tag: key) }
    public var variableTokenKey: TokenKey { TokenKey(code: .va, tag: key) }
    var whileTokenKey: TokenKey { TokenKey(code: .va, tag: "\(key).while") }
    var resultTokenKey: TokenKey { TokenKey(code: .va, tag: "\(key).result") }

// Inits ===========================================================================================
	public required init(at: V2, aether: Aether) {
		super.init(at: at, aether: aether)
		        
        whileChain = Chain(key: whileTokenKey)
        resultChain = Chain(key: resultTokenKey)

		name = "f"
		_ = addVertebra()
	}
	public required init(attributes: [String:Any], parent: Domain?) {
		super.init(attributes: attributes, parent: parent)
	}

	public var morphKey: String {
		var morphKey: String = "\(super.name);"
		vertebras.forEach {_ in morphKey += "num;"}
		return morphKey
	}

	public func add(vertebra: Vertebra) {
		add(vertebra)
		vertebras.append(vertebra)
	}
    
	public func addVertebra() -> Vertebra {
		var name: String = ""
        if vertebras.count < 4 { name = ["x", "y", "z", "w"][vertebras.count] }
        else { name = "p\(vertebras.count+1)" }

        let vertebra = Vertebra(tail: self, name: name)
        add(vertebra: vertebra)

        return vertebra
	}
	public func removeVertebra() {
		let vertebra = vertebras.removeLast()
		remove(vertebra)
	}
		
// Aexel ===========================================================================================
	public override var name: String {
		set {
			guard newValue != "" && newValue != super.name else { return }
			
			var newName: String = newValue
			var i: Int = 2
			while aether.functionExists(name: newName) {
				newName = "\(newValue)\(i)"
				i += 1
			}
			super.name = newName
		}
		get { return super.name }
	}

// Aexon ===========================================================================================
    public override var code: String { "Ta" }
    public override var tokenKeys: [TokenKey] {
        vertebras.flatMap({ $0.tokenKeys }) + [
            whileTokenKey,
            resultTokenKey,
            variableTokenKey,
            mechlikeTokenKey
        ]
    }
    public override func createCores() -> [Core] {
        vertebras.flatMap({ $0.createCores() }) + [
            ChainCore(chain: whileChain, fog: mechlikeTokenKey),
            ChainCore(chain: resultChain, fog: mechlikeTokenKey),
            TailCore(tail: self)
        ]
    }
    public override var chains: [Chain] { vertebras.flatMap({ $0.chains }) + [whileChain, resultChain] }
    public override func newNo(type: String) -> Int { vertebras.count + 1 }

// Domain ==========================================================================================
	public override var properties: [String] { super.properties + ["whileChain", "resultChain"] }
	public override var children: [String] { super.children + ["vertebras"] }
	
// VariableTokenDelegate ===========================================================================
    var alias: String? { "\(name)" }
}

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

public class Tail: Aexel, Mechlike, VariableTokenDelegate, Web {
	@objc public var whileChain: Chain!
	@objc public var resultChain: Chain!
	@objc public var vertebras: [Vertebra] = []	
	
	public var tower: Tower!

//	public var whileTower: Tower { whileChain.tower }
//	public var resultTower: Tower { resultChain.tower }

//    public var whileToken: Token { whileTower.variableToken }
//	public var resultToken: Token { resultTower.variableToken }
	
    public var mechlikeTokenKey: TokenKey { TokenKey(code: .ml, tag: name) }
    public var variableTokenKey: TokenKey { TokenKey(code: .va, tag: name) }

// Inits ===========================================================================================
	public required init(at: V2, aether: Aether) {
		super.init(at: at, aether: aether)
		        
        whileChain = Chain(key: TokenKey(code: .va, tag: "\(key).while"))
        resultChain = Chain(key: TokenKey(code: .va, tag: "\(key).result"))

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
//		vertebra.tower.web = web
		vertebras.append(vertebra)
	}
	public func addVertebra() -> Vertebra {
//		var name: String = ""
//		if vertebras.count < 4 {
//			name = ["x", "y", "z", "w"][vertebras.count]
//		} else {
//			name = "p\(vertebras.count+1)"
//		}
//
        let vertebra = Vertebra(tail: self, name: name)
//        vertebra.tower.web = web
//        vertebra.chain.tower.tailForWeb = web
//        add(vertebra: vertebra)
//        mechlikeToken.params = vertebras.count
//        vertebra.chain.tower.attach(tower)
		return vertebra
	}
	public func removeVertebra() {
//		let vertebra = vertebras.removeLast()
//        vertebra.chain.tower.detach(tower)
//		remove(vertebra)
//        mechlikeToken.params = vertebras.count
	}
		
// Events ==========================================================================================
	public override func onLoad() {
//        whileChain.tower = aether.state.createTower(tag: "\(key).while", towerDelegate: whileChain)
//        resultChain.tower = aether.state.createTower(tag: "\(key).result", towerDelegate: resultChain)
		
//        tower = aether.state.createMechlikeTower(tag: key, towerDelegate: self, tokenDelegate: self)
//        tower.mechlikeToken?.params = vertebras.count
//
//		whileTower.tailForWeb = web
//		resultTower.tailForWeb = web
//		vertebras.forEach {
//			$0.tower.web = web
//			$0.chain.tower.tailForWeb = web
//		}
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

//			if recipe != nil { AERecipeSetName(recipe, name.toInt8()) }
		}
		get { return super.name }
	}
    override public func createCores() -> [Core] {
        vertebras.flatMap({ $0.createCores() }) + [
            ChainCore(chain: whileChain),
            ChainCore(chain: resultChain),
            TailCore(tail: self)
        ]
    }

// Aexon ===========================================================================================
    public override var code: String { "Ta" }
    public override func newNo(type: String) -> Int { vertebras.count + 1 }

// Domain ==========================================================================================
	public override var properties: [String] { super.properties + ["whileChain", "resultChain"] }
	public override var children: [String] { super.children + ["vertebras"] }
	
// VariableTokenDelegate ===========================================================================
    var alias: String? { "\(name)" }
}

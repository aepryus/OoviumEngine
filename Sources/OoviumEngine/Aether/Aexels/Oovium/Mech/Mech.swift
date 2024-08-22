//
//  Mech.swift
//  Oovium
//
//  Created by Joe Charlier on 12/30/16.
//  Copyright © 2016 Aepryus Software. All rights reserved.
//

import Aegean
import Acheron
import Foundation

public protocol Mechlike: Aexel {
	var mechlikeTokenKey: TokenKey { get }
	var variableTokenKey: TokenKey { get }
}

public class Mech: Aexel, Mechlike, VariableTokenDelegate {
	@objc public var resultChain: Chain!
	@objc public var inputs: [Input] = []

    public var mechlikeTokenKey: TokenKey { TokenKey(code: .ml, tag: key) }
    public var variableTokenKey: TokenKey { TokenKey(code: .va, tag: key) }

// Inits ===========================================================================================
	public required init(at: V2, aether: Aether) {
		super.init(at: at, aether: aether)
        
        resultChain = Chain(key: TokenKey(code: .va, tag: "\(key).result"))
        
		name = "f"
		addInput()
	}
	public required init(attributes: [String:Any], parent: Domain?) {
		super.init(attributes: attributes, parent: parent)
	}
	
	public func add(input: Input) {
		add(input)
//		input.tower.web = web
		inputs.append(input)
	}
	public func addInput() {
		var name: String = ""
        if inputs.count < 4 { name = ["x", "y", "z", "w"][inputs.count] }
        else { name = "p\(inputs.count+1)" }
        let input = Input(mech: self, name: name)
		add(input: input)
//        mechlikeToken.params = inputs.count
	}
	public func removeInput() {
		let input = inputs.removeLast()
		remove(input)
//        aether.state.destroy(tower: input.tower)
//        mechlikeToken.params = inputs.count
	}
	
	
// Events ==========================================================================================
	public override func onLoad() {
//        aether.inject(chain: resultChain, tag: "\(key).result")

//        tower = aether.state.createMechlikeTower(tag: key, towerDelegate: self, tokenDelegate: self)
//        tower.mechlikeToken?.params = inputs.count
//
//		resultTower.tailForWeb = web
//		inputs.forEach {$0.tower.web = web}
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
		get { super.name }
	}
    override public func createCores() -> [Core] {
        inputs.flatMap({ $0.createCores() }) + [
            ChainCore(chain: resultChain, fog: mechlikeTokenKey),
            MechCore(mech: self)
        ]
    }
    
// Aexon ===========================================================================================
    public override var code: String { "Me" }
    public override func newNo(type: String) -> Int { inputs.count + 1 }
	
// Domain ==========================================================================================
	public override var properties: [String] { super.properties + ["resultChain"] }
	public override var children: [String] { super.children + ["inputs"] }
	
// VariableTokenDelegate ===========================================================================
    var alias: String? { "\(name)" }
}

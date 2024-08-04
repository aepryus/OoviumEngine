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

public final class Tail: Aexel, Mechlike, TowerDelegate, VariableTokenDelegate, Web {
	@objc public var whileChain: Chain!
	@objc public var resultChain: Chain!
	@objc public var vertebras: [Vertebra] = []	
	
	public var tower: Tower!

//	public var whileTower: Tower { whileChain.tower }
//	public var resultTower: Tower { resultChain.tower }

//    public var whileToken: Token { whileTower.variableToken }
//	public var resultToken: Token { resultTower.variableToken }
	
	public var web: Web { self }
	public var recipe: UnsafeMutablePointer<Recipe>? = nil
	public var morphIndex: Int? = nil

    public var mechlikeToken: MechlikeToken { tower.mechlikeToken! }
    public var variableToken: VariableToken { tower.variableToken }

// Inits ===========================================================================================
	public required init(at: V2, aether: Aether) {
		super.init(at: at, aether: aether)
		
		name = "f"
		_ = addVertebra()
	}
	public required init(attributes: [String:Any], parent: Domain?) {
		super.init(attributes: attributes, parent: parent)
	}
	deinit {
		AERecipeRelease(recipe)
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
	
	private func compileRecipe() {
//        let memory: UnsafeMutablePointer<Memory> = AEMemoryCreateClone(aether.state.memory)
//		AEMemoryClear(memory)
//		vertebras.forEach { AEMemorySetValue(memory, $0.tower.index, 0) }
//		AERecipeRelease(recipe)
//		recipe = Math.compile(tail: self, memory: memory);
//		AERecipeSignature(recipe, AEMemoryIndexForName(memory, "\(key).result".toInt8()), UInt8(vertebras.count))
//		
//		for (i, input) in vertebras.enumerated() {
//			let index = AEMemoryIndexForName(memory, "\(key).\(input.key)".toInt8())
//			recipe!.pointee.params[i] = index
//		}
//		
//		AERecipeSetMemory(recipe, memory)
	}
	
// Events ==========================================================================================
	override public func onLoad() {
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

			if recipe != nil { AERecipeSetName(recipe, name.toInt8()) }
		}
		get { return super.name }
	}
	public var towers: Set<Tower> {
        let towers = Set<Tower>()
//		vertebras.forEach {
//			towers.insert($0.tower)
//			towers.insert($0.chain.tower)
//		}
		return towers/*.union([whileTower, resultTower, tower])*/
	}
    public override var chains: [Chain] { [whileChain, resultChain] + vertebras.map({ $0.chain }) }

// Aexon ===========================================================================================
    public override var code: String { "Ta" }
    public override func newNo(type: String) -> Int { vertebras.count + 1 }

// Domain ==========================================================================================
	override public var properties: [String] { super.properties + ["whileChain", "resultChain"] }
	override public var children: [String] { super.children + ["vertebras"] }
	
// TowerDelegate ===================================================================================
	func buildUpstream(tower: Tower) {
//        whileTower.attach(tower)
//        vertebras.forEach { $0.chain.tower.attach(tower) }
//		resultTower.attach(tower)
	}
	func renderDisplay(tower: Tower) -> String {
		if tower.variableToken.status == .deleted { fatalError() }
		if tower.variableToken.status == .invalid { return "INVALID" }
		if tower.variableToken.status == .blocked { return "BLOCKED" }
		return name
	}
	func taskCompleted(tower: Tower, askedBy: Tower) -> Bool {
        return AEMemoryLoaded(tower.memory, AEMemoryIndexForName(tower.memory, variableToken.tag.toInt8())) != 0
			|| (askedBy !== tower && askedBy.web === self)
	}
	func taskBlocked(tower: Tower) -> Bool {
//		return resultChain.tower.variableToken.status != .ok
        false
	}
	func resetTask(tower: Tower) {
		recipe = nil
        AEMemoryUnfix(tower.memory, AEMemoryIndexForName(tower.memory, variableToken.tag.toInt8()))
	}
	func executeTask(tower: Tower) {
		compileRecipe()
        AEMemorySet(tower.memory, AEMemoryIndexForName(tower.memory, variableToken.tag.toInt8()), AEObjRecipe(recipe))
        AEMemoryFix(tower.memory, AEMemoryIndexForName(tower.memory, variableToken.tag.toInt8()))
		tower.variableToken.def = RecipeDef.def
	}
    
// VariableTokenDelegate ===========================================================================
    var alias: String? { "\(name)" }
}

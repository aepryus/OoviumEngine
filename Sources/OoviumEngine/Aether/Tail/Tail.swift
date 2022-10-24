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

public final class Tail: Aexel, TowerDelegate, Mechlike {
	@objc public var whileChain: Chain = Chain()
	@objc public var resultChain: Chain = Chain()
	@objc public var vertebras: [Vertebra] = []	
	
	public var tower: Tower!

	public var whileTower: Tower {
		return whileChain.tower
	}
	public var whileToken: Token {
		return whileTower.variableToken
	}
	public var resultTower: Tower {
		return resultChain.tower
	}
	public var resultToken: Token {
		return resultTower.variableToken
	}
	
	public var web: AnyObject {return self}
	public var recipe: UnsafeMutablePointer<Recipe>? = nil
	public var morphIndex: Int? = nil

	public lazy var functionToken: FunctionToken = { aether.functionToken(tag: name, recipe: "TaRcp_\(no)") }()
	public lazy var variableToken: VariableToken = { aether.variableToken(tag: "TaRcp_\(no)") }()

// Inits ===========================================================================================
	public required init(no: Int, at: V2, aether: Aether) {
		super.init(no: no, at: at, aether: aether)
		
		name = "f"
		_ = addVertebra()
		
		onLoad()
	}
	public required init(attributes: [String:Any], parent: Domain?) {
		super.init(attributes: attributes, parent: parent)
	}
	deinit {
		AERecipeRelease(recipe)
	}

	public var key: String {
		var key: String = "\(super.name);"
		vertebras.forEach {_ in key += "num;"}
		return key
	}

	public func add(vertebra: Vertebra) {
		add(vertebra)
		vertebra.tower.web = web
		vertebras.append(vertebra)
		aether.register(tower: vertebra.tower)
		aether.register(tower: vertebra.chain.tower)
	}
	public func addVertebra() -> Vertebra {
		var name: String = ""
		if vertebras.count < 4 {
			name = ["x", "y", "z", "w"][vertebras.count]
		} else {
			name = "p\(vertebras.count+1)"
		}
		let vertebra = Vertebra(tail: self, name: name)
		add(vertebra: vertebra)
		functionToken.params = vertebras.count
        vertebra.chain.tower.attach(tower)
		return vertebra
	}
	public func removeVertebra() {
		let vertebra = vertebras.removeLast()
        vertebra.chain.tower.detach(tower)
		remove(vertebra)
		aether.deregister(tower: vertebra.tower)
		aether.deregister(tower: vertebra.chain.tower)
		functionToken.params = vertebras.count
	}
	
	private func compileRecipe() {
		let memory: UnsafeMutablePointer<Memory> = AEMemoryCreateClone(aether.memory)
		AEMemoryClear(memory)
		vertebras.forEach { AEMemorySetValue(memory, $0.tower.index, 0) }
		AERecipeRelease(recipe)
		recipe = Math.compile(tail: self, memory: memory);
		AERecipeSignature(recipe, AEMemoryIndexForName(memory, "TaR_\(no)".toInt8()), UInt8(vertebras.count))
		
		for (i, input) in vertebras.enumerated() {
			let index = AEMemoryIndexForName(memory, "\(name).\(input.name)".toInt8())
			recipe!.pointee.params[i] = index
		}
		
		AERecipeSetMemory(recipe, memory)
	}
	
// Events ==========================================================================================
	override public func onLoad() {
		whileChain.tower = Tower(aether: aether, token: aether.variableToken(tag: "TaW_\(no)"), delegate: whileChain)
		resultChain.tower = Tower(aether: aether, token: aether.variableToken(tag: "TaR_\(no)"), delegate: resultChain)
		
		functionToken.params = vertebras.count
		tower = Tower(aether: aether, token: variableToken, functionToken: functionToken, delegate: self)

		whileTower.tailForWeb = web
		resultTower.tailForWeb = web
		vertebras.forEach {
			$0.tower.web = web
			$0.chain.tower.tailForWeb = web
		}
	}
	override public func onRemoved() {
		aether.deregister(tower: tower)
		vertebras.forEach {
			aether.deregister(tower: $0.tower)
			aether.deregister(tower: $0.chain.tower)
		}
		Math.deregisterMorph(key: key)
	}

// Aexel ===========================================================================================
	public override var name: String {
		set {
			guard newValue != "" && newValue != super.name else { return }
			
			Math.deregisterMorph(key: key)
			
			var newName: String = newValue
			var i: Int = 2
			while aether.functionExists(name: newName) {
				newName = "\(newValue)\(i)"
				i += 1
			}
			super.name = newName

			aether.rekey(token: functionToken, tag: name)
			functionToken.label = "\(name)("

			variableToken.label = name
			if recipe != nil { AERecipeSetName(recipe, name.toInt8()) }
		}
		get { return super.name }
	}
	public override var towers: Set<Tower> {
		var towers = Set<Tower>()
		vertebras.forEach {
			towers.insert($0.tower)
			towers.insert($0.chain.tower)
		}
		return towers.union([whileTower, resultTower, tower])
	}

// Domain ==========================================================================================
	override public var properties: [String] {
		return super.properties + ["whileChain", "resultChain"]
	}
	override public var children: [String] {
		return super.children + ["vertebras"]
	}
	
// TowerDelegate ===================================================================================
	func buildUpstream(tower: Tower) {
        whileTower.attach(tower)
        vertebras.forEach { $0.chain.tower.attach(tower) }
		resultTower.attach(tower)
	}
	func renderDisplay(tower: Tower) -> String {
		if tower.variableToken.status == .deleted { fatalError() }
		if tower.variableToken.status == .invalid { return "INVALID" }
		if tower.variableToken.status == .blocked { return "BLOCKED" }
		return name
	}
	func workerCompleted(tower: Tower, askedBy: Tower) -> Bool {
        return AEMemoryLoaded(tower.memory, AEMemoryIndexForName(aether.memory, variableToken.tag.toInt8())) != 0
			|| (askedBy !== tower && askedBy.web === self)
	}
	func workerBlocked(tower: Tower) -> Bool {
		return resultChain.tower.variableToken.status != .ok
	}
	func resetWorker(tower: Tower) {
		recipe = nil
		AEMemoryUnfix(tower.memory, AEMemoryIndexForName(aether.memory, variableToken.tag.toInt8()))
	}
	func executeWorker(tower: Tower) {
		compileRecipe()
		AEMemorySet(tower.memory, AEMemoryIndexForName(aether.memory, variableToken.tag.toInt8()), AEObjRecipe(recipe))
		AEMemoryFix(tower.memory, AEMemoryIndexForName(aether.memory, variableToken.tag.toInt8()))
		tower.variableToken.label = name
		tower.variableToken.def = RecipeDef.def
	}
}

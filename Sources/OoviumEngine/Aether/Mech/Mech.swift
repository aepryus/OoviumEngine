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
	var functionToken: FunctionToken { get }
	var variableToken: VariableToken { get }
}

public final class Mech: Aexel, TowerDelegate, Mechlike {
	@objc var resultChain: Chain = Chain()
	@objc var inputs: [Input] = []

	var tower: Tower!
//	var token: FunctionToken!

	var resultTower: Tower {
		return resultChain.tower
	}
	var resultToken: Token {
		return resultTower.variableToken
	}

	var web: AnyObject {return self}
	var recipe: UnsafeMutablePointer<Recipe>? = nil
	var morphIndex: Int? = nil

	public lazy var variableToken: VariableToken = { aether.variableToken(tag: "MeRcp_\(no)") }()
	public lazy var functionToken: FunctionToken = { aether.functionToken(tag: name, recipe: "MeRcp_\(no)") }()

// Inits ===========================================================================================
	public required init(no: Int, at: V2, aether: Aether) {
		super.init(no: no, at: at, aether: aether)

		name = "f"
		addInput()
		
		onLoad()
	}
	public required init(attributes: [String:Any], parent: Domain?) {
		super.init(attributes: attributes, parent: parent)
	}
	deinit {
		AERecipeRelease(recipe)
	}
	
	var key: String {
		var key: String = "\(super.name);"
		inputs.forEach {_ in key += "num;"}
		return key
	}
	
	func add(input: Input) {
		add(input)
		input.tower.web = web
		inputs.append(input)
		aether.register(tower: input.tower)
	}
	func addInput() {
		var name: String = ""
		if inputs.count < 4 {
			name = ["x", "y", "z", "w"][inputs.count]
		} else {
			name = "p\(inputs.count+1)"
		}
		let input = Input(mech: self, name: name)
		add(input: input)
		functionToken.params = inputs.count
	}
	func removeInput() {
		let input = inputs.removeLast()
		remove(input)
		aether.deregister(tower: input.tower)
		functionToken.params = inputs.count
	}
	
	private func compileRecipe() {
		let memory: UnsafeMutablePointer<Memory> = AEMemoryCreateClone(aether.memory)
		AEMemoryClear(memory)
		inputs.forEach {AEMemorySetValue(memory, $0.tower.index, 0)}
		AERecipeRelease(recipe)
		recipe = Math.compile(mech: self, memory: memory)
		AERecipeSignature(recipe, AEMemoryIndexForName(memory, "MeR_\(no)".toInt8()), UInt8(inputs.count))
		
		for (i, input) in inputs.enumerated() {
			let index = AEMemoryIndexForName(memory, "\(name).\(input.name)".toInt8())
			recipe!.pointee.params[i] = index
		}
	
		AERecipeSetMemory(recipe, memory)
	}
	
// Events ==========================================================================================
	override public func onLoad() {
		resultChain.tower = Tower(aether: aether, token: aether.variableToken(tag: "MeR_\(no)"), delegate: resultChain)
		
		functionToken.params = inputs.count
		tower = Tower(aether: aether, token: variableToken, functionToken: functionToken, delegate: self)

		resultTower.tailForWeb = web
		inputs.forEach {$0.tower.web = web}
	}
	override public func onRemoved() {
		aether.deregister(tower: tower)
		inputs.forEach { aether.deregister(tower: $0.tower) }
		Math.deregisterMorph(key: key)
	}
	
// Aexel ===========================================================================================
	override var name: String {
		set {
			guard newValue != "" && newValue != super.name else {return}
			
			Math.deregisterMorph(key: super.name)
			
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
		get {return super.name}
	}
	override var towers: Set<Tower> {
		var towers = Set<Tower>()
		inputs.forEach {towers.insert($0.tower)}
		return towers.union([resultTower, tower])
	}
	
// Domain ==========================================================================================
	override public var properties: [String] {
		return super.properties + ["resultChain"]
	}
	override public var children: [String] {
		return super.children + ["inputs"]
	}
	
// TowerDelegate ===================================================================================
	func buildUpstream(tower: Tower) {
		resultTower.attach(tower)
	}
	func renderDisplay(tower: Tower) -> String {
		if tower.variableToken.status == .deleted { fatalError() }
		if tower.variableToken.status == .invalid { return "INVALID" }
		if tower.variableToken.status == .blocked { return "BLOCKED" }
		return name
	}
	func workerCompleted(tower: Tower, askedBy: Tower) -> Bool {
		return AEMemoryLoaded(tower.aether.memory, AEMemoryIndexForName(aether.memory, variableToken.tag.toInt8())) != 0
			|| (askedBy !== tower && askedBy.web === self)
	}
	func workerBlocked(tower: Tower) -> Bool {
		return resultChain.tower.variableToken.status != .ok
	}
	func resetWorker(tower: Tower) {
		recipe = nil
		AEMemoryUnfix(tower.aether.memory, AEMemoryIndexForName(aether.memory, variableToken.tag.toInt8()))
	}
	func executeWorker(tower: Tower) {
		compileRecipe()
		AEMemorySet(tower.aether.memory, AEMemoryIndexForName(aether.memory, variableToken.tag.toInt8()), AEObjRecipe(recipe))
		AEMemoryFix(tower.aether.memory, AEMemoryIndexForName(aether.memory, variableToken.tag.toInt8()))
		tower.variableToken.label = name
		tower.variableToken.def = RecipeDef.def
	}
}

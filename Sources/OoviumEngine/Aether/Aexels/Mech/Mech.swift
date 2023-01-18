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
	var mechlikeToken: MechlikeToken { get }
	var variableToken: VariableToken { get }
}

public final class Mech: Aexel, Mechlike, TowerDelegate, VariableTokenDelegate {
	@objc public var resultChain: Chain = Chain()
	@objc public var inputs: [Input] = []

	public var tower: Tower!

	public var resultTower: Tower { resultChain.tower }
	var resultToken: Token { resultTower.variableToken }

	var web: AnyObject { self }
	var recipe: UnsafeMutablePointer<Recipe>? = nil
//	var morphIndex: Int? = nil

    public var variableToken: VariableToken { tower.variableToken }
    public var mechlikeToken: MechlikeToken { tower.mechlikeToken! }

// Inits ===========================================================================================
	public required init(no: Int, at: V2, aether: Aether) {
		super.init(no: no, at: at, aether: aether)
        
		name = "f"
		addInput()
	}
	public required init(attributes: [String:Any], parent: Domain?) {
		super.init(attributes: attributes, parent: parent)
	}
	deinit { AERecipeRelease(recipe) }
	
	public func add(input: Input) {
		add(input)
		input.tower.web = web
		inputs.append(input)
	}
	public func addInput() {
		var name: String = ""
        if inputs.count < 4 { name = ["x", "y", "z", "w"][inputs.count] }
        else { name = "p\(inputs.count+1)" }
        let input = Input(mech: self, name: name, no: inputs.count+1)
		add(input: input)
        mechlikeToken.params = inputs.count
	}
	public func removeInput() {
		let input = inputs.removeLast()
		remove(input)
        aether.destroy(tower: input.tower)
        mechlikeToken.params = inputs.count
	}
	
	private func compileRecipe() {
		let memory: UnsafeMutablePointer<Memory> = AEMemoryCreateClone(aether.memory)
		AEMemoryClear(memory)
		inputs.forEach {AEMemorySetValue(memory, $0.tower.index, 0)}
		AERecipeRelease(recipe)
		recipe = Math.compile(mech: self, memory: memory)
		AERecipeSignature(recipe, AEMemoryIndexForName(memory, "\(key).result".toInt8()), UInt8(inputs.count))
		
		for (i, input) in inputs.enumerated() {
			let index = AEMemoryIndexForName(memory, "\(key).\(input.key)".toInt8())
			recipe!.pointee.params[i] = index
		}
        
        let towers: Set<Tower> = resultTower.towersDestinedFor()
        towers.forEach { AEMemoryMarkLoaded(memory, $0.index) }
        
        let index: mnimi = AEMemoryIndexForName(memory, variableToken.tag.toInt8())
        AEMemorySet(memory, index, AEObjRecipe(recipe))
        AEMemoryFix(memory, index)

		AERecipeSetMemory(recipe, memory)
	}
	
// Events ==========================================================================================
	override public func onLoad() {
        resultChain.tower = aether.createTower(tag: "\(key).result", towerDelegate: resultChain)

        tower = aether.createMechlikeTower(tag: key, towerDelegate: self, tokenDelegate: self)
        tower.mechlikeToken?.params = inputs.count

		resultTower.tailForWeb = web
		inputs.forEach {$0.tower.web = web}
	}
	
// Aexel ===========================================================================================
    public override var code: String { "Me" }
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
		get { super.name }
	}
	public override var towers: Set<Tower> {
		var towers = Set<Tower>()
		inputs.forEach { towers.insert($0.tower) }
		return towers.union([resultTower, tower])
	}
	
// Domain ==========================================================================================
	override public var properties: [String] { super.properties + ["resultChain"] }
	override public var children: [String] { super.children + ["inputs"] }
	
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
//    func buildWorker(tower: Tower) {}
	func workerCompleted(tower: Tower, askedBy: Tower) -> Bool {
		AEMemoryLoaded(tower.memory, AEMemoryIndexForName(aether.memory, variableToken.tag.toInt8())) != 0 || (askedBy !== tower && askedBy.web === self)
	}
	func workerBlocked(tower: Tower) -> Bool { resultChain.tower.variableToken.status != .ok }
	func resetWorker(tower: Tower) {
		recipe = nil
		AEMemoryUnfix(tower.memory, AEMemoryIndexForName(aether.memory, variableToken.tag.toInt8()))
	}
	func executeWorker(tower: Tower) {
		compileRecipe()
		AEMemorySet(tower.memory, AEMemoryIndexForName(aether.memory, variableToken.tag.toInt8()), AEObjRecipe(recipe))
		AEMemoryFix(tower.memory, AEMemoryIndexForName(aether.memory, variableToken.tag.toInt8()))
		tower.variableToken.def = RecipeDef.def
	}
    
// VariableTokenDelegate ===========================================================================
    var alias: String? { "\(name)" }
}

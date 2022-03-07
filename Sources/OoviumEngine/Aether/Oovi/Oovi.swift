//
//  Oovi.swift
//  Oovium
//
//  Created by Joe Charlier on 10/24/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import Aegean
import Acheron
import Foundation

public class Oovi: Aexel, TowerDelegate {
	@objc override public var name: String {
		didSet{nameChanged()}
	}
	@objc public var color: OOColor = OOColor.white
	@objc public var stepChain: Chain!
	@objc public var amorousChain: Chain!
	
	var web: AnyObject {return self}

	var parameterTowers: Set<Tower> = Set<Tower>()
	
	public var amorousRecipe: UnsafeMutablePointer<Recipe>? = nil
	public var stepRecipe: UnsafeMutablePointer<Recipe>? = nil
	
	var stepTower: Tower {
		return stepChain.tower
	}
	var amorousTower: Tower {
		return amorousChain.tower
	}

	public required init(no: Int, at: V2, aether: Aether) {
		stepChain = Chain()
		amorousChain = Chain()
		
		super.init(no: no, at:at, aether: aether)
	}
	public required init(attributes: [String:Any], parent: Domain?) {
		super.init(attributes: attributes, parent: parent)
	}
	deinit {
		AERecipeRelease(amorousRecipe)
		AERecipeRelease(stepRecipe)
	}
	
//	public var uiColor: UIColor {
//		return color.uiColor
//	}
	
	private func nameChanged() {
		aether.name = name
	}
	
	private func foreshadow(memory: UnsafeMutablePointer<Memory>) {
		AEMemorySetValue(memory, AEMemoryIndexForName(memory, "Oovi\(no).speed".toInt8()), 0)
		AEMemorySetValue(memory, AEMemoryIndexForName(memory, "Oovi\(no).energy".toInt8()), 0)
		AEMemorySetValue(memory, AEMemoryIndexForName(memory, "Oovi\(no).vision".toInt8()), 0)
		AEMemorySetValue(memory, AEMemoryIndexForName(memory, "Oovi\(no).attack".toInt8()), 0)
		AEMemorySetValue(memory, AEMemoryIndexForName(memory, "Oovi\(no).armor".toInt8()), 0)
		AEMemorySetValue(memory, AEMemoryIndexForName(memory, "Oovi\(no).health".toInt8()), 0)

		AEMemorySetValue(memory, AEMemoryIndexForName(memory, "Oovi\(no).fruits".toInt8()), 0)
		AEMemorySetValue(memory, AEMemoryIndexForName(memory, "Oovi\(no).mates".toInt8()), 0)
		AEMemorySetValue(memory, AEMemoryIndexForName(memory, "Oovi\(no).friends".toInt8()), 0)
		AEMemorySetValue(memory, AEMemoryIndexForName(memory, "Oovi\(no).enemies".toInt8()), 0)

		AEMemorySetValue(memory, AEMemoryIndexForName(memory, "Oovi\(no).capacity".toInt8()), 0)
		AEMemorySetValue(memory, AEMemoryIndexForName(memory, "Oovi\(no).remaining".toInt8()), 0)
		AEMemorySetValue(memory, AEMemoryIndexForName(memory, "Oovi\(no).used".toInt8()), 0)
		AEMemorySetValue(memory, AEMemoryIndexForName(memory, "Oovi\(no).hunger".toInt8()), 0)

		AEMemorySetValue(memory, AEMemoryIndexForName(memory, "Oovi\(no).gender".toInt8()), 0)
		AEMemorySetValue(memory, AEMemoryIndexForName(memory, "Oovi\(no).pregnant".toInt8()), 0)
		AEMemorySetValue(memory, AEMemoryIndexForName(memory, "Oovi\(no).damage".toInt8()), 0)
		
		AEMemorySetValue(memory, AEMemoryIndexForName(memory, "chill".toInt8()), 0)
		AEMemorySetValue(memory, AEMemoryIndexForName(memory, "eat".toInt8()), 0)
		AEMemorySetValue(memory, AEMemoryIndexForName(memory, "flirt".toInt8()), 0)
		AEMemorySetValue(memory, AEMemoryIndexForName(memory, "fight".toInt8()), 0)
		AEMemorySetValue(memory, AEMemoryIndexForName(memory, "flee".toInt8()), 0)
		AEMemorySetValue(memory, AEMemoryIndexForName(memory, "wander".toInt8()), 0)
	}
	public func compileRecipies() {
		objc_sync_enter(self)
		defer {objc_sync_exit(self)}
		
		aether.evaluate()

		let memory: UnsafeMutablePointer<Memory> = AEMemoryCreateClone(aether.memory)

		AEMemoryClear(memory)
		foreshadow(memory: memory)
		AERecipeRelease(amorousRecipe)
		amorousRecipe = Math.compile(result: amorousTower, memory: memory)

		AEMemoryClear(memory)
		foreshadow(memory: memory)
		AERecipeRelease(stepRecipe)
		stepRecipe = Math.compile(result: stepTower, memory: memory)
		
		AEMemoryRelease(memory)
	}
	
	private func buildParameterTowers() {
		parameterTowers.insert(Tower(aether: aether, token: aether.variableToken(tag: "Oovi\(no).speed", label: "speed"), delegate: self))
		parameterTowers.insert(Tower(aether: aether, token: aether.variableToken(tag: "Oovi\(no).energy", label: "energy"), delegate: self))
		parameterTowers.insert(Tower(aether: aether, token: aether.variableToken(tag: "Oovi\(no).vision", label: "vision"), delegate: self))
		parameterTowers.insert(Tower(aether: aether, token: aether.variableToken(tag: "Oovi\(no).attack", label: "attack"), delegate: self))
		parameterTowers.insert(Tower(aether: aether, token: aether.variableToken(tag: "Oovi\(no).armor", label: "armor"), delegate: self))
		parameterTowers.insert(Tower(aether: aether, token: aether.variableToken(tag: "Oovi\(no).health", label: "health"), delegate: self))

		parameterTowers.insert(Tower(aether: aether, token: aether.variableToken(tag: "Oovi\(no).fruits", label: "fruits"), delegate: self))
		parameterTowers.insert(Tower(aether: aether, token: aether.variableToken(tag: "Oovi\(no).mates", label: "mates"), delegate: self))
		parameterTowers.insert(Tower(aether: aether, token: aether.variableToken(tag: "Oovi\(no).friends", label: "friends"), delegate: self))
		parameterTowers.insert(Tower(aether: aether, token: aether.variableToken(tag: "Oovi\(no).enemies", label: "enemies"), delegate: self))

		parameterTowers.insert(Tower(aether: aether, token: aether.variableToken(tag: "Oovi\(no).capacity", label: "capacity"), delegate: self))
		parameterTowers.insert(Tower(aether: aether, token: aether.variableToken(tag: "Oovi\(no).remaining", label: "remaining"), delegate: self))
		parameterTowers.insert(Tower(aether: aether, token: aether.variableToken(tag: "Oovi\(no).used", label: "used"), delegate: self))
		parameterTowers.insert(Tower(aether: aether, token: aether.variableToken(tag: "Oovi\(no).hunger", label: "hunger"), delegate: self))

		parameterTowers.insert(Tower(aether: aether, token: aether.variableToken(tag: "Oovi\(no).gender", label: "gender"), delegate: self))
		parameterTowers.insert(Tower(aether: aether, token: aether.variableToken(tag: "Oovi\(no).pregnant", label: "pregnant"), delegate: self))
		parameterTowers.insert(Tower(aether: aether, token: aether.variableToken(tag: "Oovi\(no).damage", label: "damage"), delegate: self))

		parameterTowers.insert(Tower(aether: aether, token: aether.variableToken(tag: "chill", label: "chill"), delegate: self))
		parameterTowers.insert(Tower(aether: aether, token: aether.variableToken(tag: "eat", label: "eat"), delegate: self))
		parameterTowers.insert(Tower(aether: aether, token: aether.variableToken(tag: "flirt", label: "flirt"), delegate: self))
		parameterTowers.insert(Tower(aether: aether, token: aether.variableToken(tag: "fight", label: "fight"), delegate: self))
		parameterTowers.insert(Tower(aether: aether, token: aether.variableToken(tag: "flee", label: "flee"), delegate: self))
		parameterTowers.insert(Tower(aether: aether, token: aether.variableToken(tag: "wander", label: "wander"), delegate: self))

		for tower in parameterTowers {
			tower.web = web
		}
	}
	
// Events ==========================================================================================
	override public func onLoad() {
		amorousChain.tower = Tower(aether: aether, token: aether.variableToken(tag: "OoA_\(no)"), delegate: amorousChain)
		stepChain.tower = Tower(aether: aether, token: aether.variableToken(tag: "OoS_\(no)"), delegate: stepChain)
		
		amorousTower.tailForWeb = web
		stepTower.tailForWeb = web
		
		buildParameterTowers()
	}
	
// Aexel ===========================================================================================
	public override var towers: Set<Tower> {
		return parameterTowers.union([amorousTower, stepTower])
	}

// Domain ==========================================================================================
    override open var properties: [String] {
        return super.properties + ["color", "stepChain", "amorousChain"]
    }
}

//
//  AutomataCore.swift
//  OoviumEngine
//
//  Created by Joe Charlier on 5/6/25.
//

import Aegean

public class AutomataCore: Core {
    let automata: Automata

    var recipe: UnsafeMutablePointer<Recipe>? = nil

    var resultTower: Tower!

    init(automata: Automata) { self.automata = automata }
    deinit { AERecipeRelease(recipe) }

// Recipe ==========================================================================================
    public func compile(memory: UnsafeMutablePointer<Memory>) -> UnsafeMutablePointer<Recipe> {
        var tasks = [UnsafeMutablePointer<Task>]()
        
        _ = MechCore.program(tasks: &tasks, tail: resultTower, memory: memory, additional: resultTower.stronglyLinked(), completed: Set<Tower>(), n: 0)
        
        let recipe = AERecipeCreate(tasks.count)!
        var i = 0
        for task in tasks {
            recipe.pointee.tasks[i] = task
            i += 1
        }
        AERecipeSetName(recipe, automata.name.toInt8())
        
        return recipe
    }

    private func compileRecipe() {
        let memory: UnsafeMutablePointer<Memory> = AEMemoryCreateClone(citadel.memory)
        AEMemoryClear(memory)
        
        AEMemorySetValue(memory, citadel.tower(key: automata.selfTokenKey)!.index, 0)
        AEMemorySetValue(memory, citadel.tower(key: automata.aTokenKey)!.index, 0)
        AEMemorySetValue(memory, citadel.tower(key: automata.bTokenKey)!.index, 0)
        AEMemorySetValue(memory, citadel.tower(key: automata.cTokenKey)!.index, 0)
        AEMemorySetValue(memory, citadel.tower(key: automata.dTokenKey)!.index, 0)
        AEMemorySetValue(memory, citadel.tower(key: automata.eTokenKey)!.index, 0)
        AEMemorySetValue(memory, citadel.tower(key: automata.fTokenKey)!.index, 0)
        AEMemorySetValue(memory, citadel.tower(key: automata.gTokenKey)!.index, 0)
        AEMemorySetValue(memory, citadel.tower(key: automata.hTokenKey)!.index, 0)

        AERecipeRelease(recipe)
        recipe = compile(memory: memory)
        AERecipeSignature(recipe, AEMemoryIndexForName(memory, "\(automata.key).result".toInt8()), UInt8(9))

        recipe!.pointee.params[0] = AEMemoryIndexForName(memory, "\(automata.selfTokenKey.tag)".toInt8())
        recipe!.pointee.params[1] = AEMemoryIndexForName(memory, "\(automata.aTokenKey.tag)".toInt8())
        recipe!.pointee.params[2] = AEMemoryIndexForName(memory, "\(automata.bTokenKey.tag)".toInt8())
        recipe!.pointee.params[3] = AEMemoryIndexForName(memory, "\(automata.cTokenKey.tag)".toInt8())
        recipe!.pointee.params[4] = AEMemoryIndexForName(memory, "\(automata.dTokenKey.tag)".toInt8())
        recipe!.pointee.params[5] = AEMemoryIndexForName(memory, "\(automata.eTokenKey.tag)".toInt8())
        recipe!.pointee.params[6] = AEMemoryIndexForName(memory, "\(automata.fTokenKey.tag)".toInt8())
        recipe!.pointee.params[7] = AEMemoryIndexForName(memory, "\(automata.gTokenKey.tag)".toInt8())
        recipe!.pointee.params[8] = AEMemoryIndexForName(memory, "\(automata.hTokenKey.tag)".toInt8())
    }

// Core ============================================================================================
    override var key: TokenKey { automata.variableTokenKey }
    
//    override func createTower(_ citadel: Citadel) -> Tower { citadel.createMechlikeTower(tag: key.tag, core: self, tokenDelegate: mech) }
    override func createTowerTokens(_ citadel: Citadel) -> [TowerToken] { [
        citadel.towerToken(key: automata.variableTokenKey, delegate: automata),
        citadel.towerToken(key: automata.mechlikeTokenKey, delegate: automata)
    ] }
    override func citadelCompleted(_ citadel: Citadel) {
        resultTower = citadel.tower(key: automata.resultChain.key!)
    }

    override func buildUpstream(tower: Tower) {
        resultTower.attach(tower)
    }
    override func renderDisplay(tower: Tower) -> String {
        if tower.variableToken.status == .deleted { fatalError() }
        if tower.variableToken.status == .invalid { return "INVALID" }
        if tower.variableToken.status == .blocked { return "BLOCKED" }
        return automata.name
    }
    override func taskCompleted(tower: Tower, askedBy: Tower) -> Bool {
        AEMemoryLoaded(tower.memory, AEMemoryIndexForName(tower.memory, automata.variableTokenKey.tag.toInt8())) != 0
            || (askedBy !== tower && askedBy.fog == automata.mechlikeTokenKey)
    }
    override func taskBlocked(tower: Tower) -> Bool {
        resultTower.variableToken.status != .ok
    }
    override func resetTask(tower: Tower) {
        recipe = nil
        AEMemoryUnfix(tower.memory, AEMemoryIndexForName(tower.memory, automata.variableTokenKey.tag.toInt8()))
    }
    override func executeTask(tower: Tower) {
        compileRecipe()
        AEMemorySet(tower.memory, AEMemoryIndexForName(tower.memory, automata.variableTokenKey.tag.toInt8()), AEObjRecipe(recipe))
        AEMemoryFix(tower.memory, AEMemoryIndexForName(tower.memory, automata.variableTokenKey.tag.toInt8()))
        tower.variableToken.def = RecipeDef.def
    }
}

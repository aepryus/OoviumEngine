//
//  OoviCore.swift
//  OoviumEngine
//
//  Created by Joe Charlier on 4/17/26.
//  Copyright © 2026 Aepryus Software. All rights reserved.
//

import Aegean

public class OoviCore: Core {
    let oovi: Oovi

    public var amorousRecipe: UnsafeMutablePointer<Recipe>? = nil
    public var stepRecipe: UnsafeMutablePointer<Recipe>? = nil

    var amorousResultTower: Tower!
    var stepResultTower: Tower!

    init(oovi: Oovi) { self.oovi = oovi }
    deinit {
        AERecipeRelease(amorousRecipe)
        AERecipeRelease(stepRecipe)
    }

// Recipe ==========================================================================================
    public func compile(chain: Chain, memory: UnsafeMutablePointer<Memory>) -> UnsafeMutablePointer<Recipe> {
        let tail: Tower = (chain === oovi.amorousChain) ? amorousResultTower : stepResultTower
        var tasks = [UnsafeMutablePointer<Task>]()

        _ = MechCore.program(tasks: &tasks, tail: tail, memory: memory, additional: tail.stronglyLinked(), completed: Set<Tower>(), n: 0)

        let recipe = AERecipeCreate(tasks.count)!
        var i = 0
        for task in tasks {
            recipe.pointee.tasks[i] = task
            i += 1
        }
        AERecipeSetName(recipe, chain.key!.tag.toInt8())

        return recipe
    }

    public func compileRecipes() {
        let memory: UnsafeMutablePointer<Memory> = AEMemoryCreateClone(citadel.memory)
        AEMemoryClear(memory)
        oovi.paramTokenKeys.forEach {
            if let index: mnimi = citadel.tower(key: $0)?.index {
                AEMemorySetValue(memory, index, 0)
            }
        }

        AERecipeRelease(amorousRecipe)
        amorousRecipe = compile(chain: oovi.amorousChain, memory: memory)

        AERecipeRelease(stepRecipe)
        stepRecipe = compile(chain: oovi.stepChain, memory: memory)

        AEMemoryRelease(memory)
    }

// Core ============================================================================================
    override var key: TokenKey { oovi.variableTokenKey }

    override func createTowerTokens(_ citadel: Citadel) -> [TowerToken] { [
        citadel.towerToken(key: oovi.variableTokenKey, delegate: oovi),
        citadel.towerToken(key: oovi.mechlikeTokenKey, delegate: oovi)
    ] }
    override func citadelCompleted(_ citadel: Citadel) {
        amorousResultTower = citadel.tower(key: oovi.amorousChain.key!)
        stepResultTower = citadel.tower(key: oovi.stepChain.key!)
    }

    override func renderDisplay(tower: Tower) -> String {
        if tower.variableToken.status == .deleted { fatalError() }
        if tower.variableToken.status == .invalid { return "INVALID" }
        if tower.variableToken.status == .blocked { return "BLOCKED" }
        return oovi.name
    }
    override func taskBlocked(tower: Tower) -> Bool {
        amorousResultTower.variableToken.status != .ok || stepResultTower.variableToken.status != .ok
    }
    override func executeTask(tower: Tower) {
        compileRecipes()
    }
}

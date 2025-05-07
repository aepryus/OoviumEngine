//
//  MechCore.swift
//  OoviumEngine
//
//  Created by Joe Charlier on 8/5/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import Aegean
import Foundation

public class MechCore: Core {
    let mech: Mech

    var recipe: UnsafeMutablePointer<Recipe>? = nil

    var resultTower: Tower!

    init(mech: Mech) { self.mech = mech }
    deinit { AERecipeRelease(recipe) }

// Recipe ==========================================================================================
    static func program(tasks: inout [UnsafeMutablePointer<Task>], tail: Tower, memory: UnsafeMutablePointer<Memory>, additional: Set<Tower>, completed: Set<Tower>, n: Int) -> Int {
        var n = n
        var completed = completed
        var progress: Bool
        
        var gates: [Tower] = []
        
        completed.formUnion(additional)
        
        repeat {
            progress = false
            
            for tower in additional {
                guard tower.attemptToFire(memory) else {continue}
                
                progress = true
                tasks.append(AETaskCreateClone(tower.task!))
                n += 1
                
                if tower.gateTo != nil {gates.append(tower)}
            }
            
            for gate in gates {
                let thenTowers: Set<Tower> = tail.stronglyLinked(override: gate.thenTo).subtracting(completed)
                let elseTowers: Set<Tower> = tail.stronglyLinked(override: gate.elseTo).subtracting(completed)
                
                guard thenTowers != elseTowers else { continue }
                
                progress = true
                
                let ifGotoIndex = n
                tasks.append(AETaskCreateIfGoto(0, 0))
                n += 1
                
                n = program(tasks: &tasks, tail: tail, memory: AEMemoryCreateClone(memory), additional: thenTowers, completed: completed, n: n)
                var ifGotoN = n+1
                
                let gotoIndex = n
                tasks.append(AETaskCreateGoto(0))
                n += 1
                let oldN = n
                n = program(tasks: &tasks, tail: tail, memory: AEMemoryCreateClone(memory), additional: elseTowers, completed: completed, n: n)
                if oldN != n {
                    AETaskRelease(tasks[gotoIndex])
                    tasks[gotoIndex] = AETaskCreateGoto(UInt8(n))
                    AETaskSetLabels(tasks[gotoIndex], "".toInt8(), "GOTO \(n)".toInt8())
                } else {
                    tasks.removeLast()
                    n -= 1
                    ifGotoN -= 1
                }
                
                AETaskRelease(tasks[ifGotoIndex])
                tasks[ifGotoIndex] = AETaskCreateIfGoto(AEMemoryIndexForName(memory, gate.name.toInt8()), UInt8(ifGotoN))
                AETaskSetLabels(tasks[ifGotoIndex], "".toInt8(), "IF \(gate.name) == FALSE GOTO \(ifGotoN)".toInt8())
                
                memory.pointee.slots[Int(gate.gateTo!.index)].loaded = 1
                tasks.append(AETaskCreateClone(gate.gateTo!.task!))
                n += 1
            }
            gates.removeAll()
            
        } while (progress)
        
        return n
    }
    public func compile(memory: UnsafeMutablePointer<Memory>) -> UnsafeMutablePointer<Recipe> {
        var tasks = [UnsafeMutablePointer<Task>]()
        
        _ = MechCore.program(tasks: &tasks, tail: resultTower, memory: memory, additional: resultTower.stronglyLinked(), completed: Set<Tower>(), n: 0)
        
        let recipe = AERecipeCreate(tasks.count)!
        var i = 0
        for task in tasks {
            recipe.pointee.tasks[i] = task
            i += 1
        }
        AERecipeSetName(recipe, mech.name.toInt8())
        
        return recipe
    }

    private func compileRecipe() {
        let memory: UnsafeMutablePointer<Memory> = AEMemoryCreateClone(citadel.memory)
        AEMemoryClear(memory)
        mech.inputs.forEach { AEMemorySetValue(memory, citadel.tower(key: $0.tokenKey)!.index, 0) }
        AERecipeRelease(recipe)
        recipe = compile(memory: memory)
        AERecipeSignature(recipe, AEMemoryIndexForName(memory, "\(mech.key).result".toInt8()), UInt8(mech.inputs.count))

        for (i, input) in mech.inputs.enumerated() {
            let index = AEMemoryIndexForName(memory, "\(input.fullKey)".toInt8())
            recipe!.pointee.params[i] = index
        }

        /*
         
         The following code does not appear in the corresponding area for TailCore.  I was unsure why and
         commented it out, but it broke recursion and have put it back in.
         
         I'm still trying to work out what this is doing, but the setting of the Recipe in the Recipe's own
         memory is done for recursion, giving access to itself.  Since Tail never calls itself recursively
         it is unnecessary there.  (Although perhaps there is nothing preventing this from happening, yet)
         
         The first part setting all the "destined for" towers to load I think is unnecessary; the Recipes do
         not pay attention to the flag; it is only used to determine the order of the lines when building
         the recipe itself or during calculation of fixed bubbles.
         
             -jjc 8/14/24
        
         */
        let towers: Set<Tower> = resultTower.towersDestinedFor()
        towers.forEach { AEMemoryMarkLoaded(memory, $0.index) }

        let index: mnimi = AEMemoryIndexForName(memory, mech.key.toInt8())
        AEMemorySet(memory, index, AEObjRecipe(recipe))
        AEMemoryFix(memory, index)
        // =========================================================================================
        
        AERecipeSetMemory(recipe, memory)
    }

// Core ===================================================================================
    override var key: TokenKey { mech.variableTokenKey }
    
//    override func createTower(_ citadel: Citadel) -> Tower { citadel.createMechlikeTower(tag: key.tag, core: self, tokenDelegate: mech) }
    override func createTowerTokens(_ citadel: Citadel) -> [TowerToken] { [
        citadel.towerToken(key: mech.variableTokenKey, delegate: mech),
        citadel.towerToken(key: mech.mechlikeTokenKey, delegate: mech)
    ] }
    override func citadelCompleted(_ citadel: Citadel) {
        resultTower = citadel.tower(key: mech.resultChain.key!)
    }

    override func buildUpstream(tower: Tower) {
        resultTower.attach(tower)
    }
    override func renderDisplay(tower: Tower) -> String {
        if tower.variableToken.status == .deleted { fatalError() }
        if tower.variableToken.status == .invalid { return "INVALID" }
        if tower.variableToken.status == .blocked { return "BLOCKED" }
        return mech.name
    }
    override func taskCompleted(tower: Tower, askedBy: Tower) -> Bool {
        AEMemoryLoaded(tower.memory, AEMemoryIndexForName(tower.memory, mech.variableTokenKey.tag.toInt8())) != 0
            || (askedBy !== tower && askedBy.fog == mech.mechlikeTokenKey)
    }
    override func taskBlocked(tower: Tower) -> Bool {
        resultTower.variableToken.status != .ok
    }
    override func resetTask(tower: Tower) {
        recipe = nil
        AEMemoryUnfix(tower.memory, AEMemoryIndexForName(tower.memory, mech.variableTokenKey.tag.toInt8()))
    }
    override func executeTask(tower: Tower) {
        compileRecipe()
        AEMemorySet(tower.memory, AEMemoryIndexForName(tower.memory, mech.variableTokenKey.tag.toInt8()), AEObjRecipe(recipe))
        AEMemoryFix(tower.memory, AEMemoryIndexForName(tower.memory, mech.variableTokenKey.tag.toInt8()))
        tower.variableToken.def = RecipeDef.def
    }
}

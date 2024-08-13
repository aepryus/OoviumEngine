//
//  TailCore.swift
//  OoviumEngine
//
//  Created by Joe Charlier on 8/5/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import Aegean
import Foundation

class TailCore: Core {
    let tail: Tail
    
    public var recipe: UnsafeMutablePointer<Recipe>? = nil
    public var morphIndex: Int? = nil
    
    var whileTower: Tower!
    var resultTower: Tower!

    init(tail: Tail) { self.tail = tail }
    deinit { AERecipeRelease(recipe) }
    
    private func compile(memory: UnsafeMutablePointer<Memory>) -> UnsafeMutablePointer<Recipe> {
        var tasks: [UnsafeMutablePointer<Task>] = []
        var n: Int = 0
        var completed: Set<Tower> = Set<Tower>()
        
        var additional: Set<Tower> = whileTower.stronglyLinked()
        n = MechCore.program(tasks: &tasks, tail: whileTower, memory: memory, additional: additional, completed: completed, n: n)
        completed.formUnion(additional)
        
        let ifGotoIndex = n
        tasks.append(AETaskCreateIfGoto(0, 0))
        n += 1
        
//        for vertebra in tail.vertebras {
//            additional = vertebra.chain.tower.stronglyLinked()
//            n = program(tasks: &tasks, tail: vertebra.chain.tower, memory: memory, additional: additional, completed: completed, n: n)
//            completed.formUnion(additional)
//        }
//        
//        for vertebra in tail.vertebras {
//            tasks.append(AETaskCreateAssign(
//                AEMemoryIndexForName(memory, vertebra.chain.tower.name.toInt8()),
//                AEMemoryIndexForName(memory, vertebra.tower.name.toInt8())
//            ));
//            AETaskSetLabels(tasks[n], "".toInt8(), "\(vertebra.tower.name) = \(vertebra.chain.tower.name)".toInt8())
//            n += 1
//        }
        for vertebra in tail.vertebras {
            let vertebraTower: Tower = aetherExe.tower(key: vertebra.chain.key!)!
            additional = vertebraTower.stronglyLinked()
            n = MechCore.program(tasks: &tasks, tail: vertebraTower, memory: memory, additional: additional, completed: completed, n: n)
            completed.formUnion(additional)
        }
        
//        for vertebra in tail.vertebras {
//            tasks.append(AETaskCreateAssign(
//                AEMemoryIndexForName(memory, vertebra.chain.tower.name.toInt8()),
//                AEMemoryIndexForName(memory, vertebra.tower.name.toInt8())
//            ));
//            AETaskSetLabels(tasks[n], "".toInt8(), "\(vertebra.tower.name) = \(vertebra.chain.tower.name)".toInt8())
//            n += 1
//        }
        for vertebra in tail.vertebras {
            tasks.append(AETaskCreateAssign(
                AEMemoryIndexForName(memory, aetherExe.tower(key: vertebra.chain.key!)!.name.toInt8()),
                AEMemoryIndexForName(memory, aetherExe.tower(key: vertebra.tokenKey)!.name.toInt8())
            ));
            AETaskSetLabels(tasks[n], "".toInt8(), "\(aetherExe.tower(key: vertebra.tokenKey)!.name) = \(aetherExe.tower(key: vertebra.chain.key!)!.name)".toInt8())
            n += 1
        }
        
        tasks.append(AETaskCreateGoto(UInt8(0)))
        AETaskSetLabels(tasks[n], "".toInt8(), "GOTO \(0)".toInt8())
        n += 1

        AETaskRelease(tasks[ifGotoIndex])
        tasks[ifGotoIndex] = AETaskCreateIfGoto(AEMemoryIndexForName(memory, whileTower.name.toInt8()), UInt8(n))
        AETaskSetLabels(tasks[ifGotoIndex], "".toInt8(), "IF \(whileTower.name) == FALSE GOTO \(n)".toInt8())

        additional = resultTower.stronglyLinked()
        _ = MechCore.program(tasks: &tasks, tail: resultTower, memory: memory, additional: additional, completed: completed, n: n)

        let recipe = AERecipeCreate(tasks.count)!
        var i = 0
        for task in tasks {
            recipe.pointee.tasks[i] = task
            i += 1
        }
        AERecipeSetName(recipe, tail.name.toInt8())
        
        return recipe
    }

    private func compileRecipe() {
        let memory: UnsafeMutablePointer<Memory> = AEMemoryCreateClone(aetherExe.memory)
        AEMemoryClear(memory)
        tail.vertebras.forEach { AEMemorySetValue(memory, aetherExe.tower(key: $0.tokenKey)!.index, 0) }
        AERecipeRelease(recipe)
        recipe = compile(memory: memory)
        AERecipeSignature(recipe, AEMemoryIndexForName(memory, "\(tail.key).result".toInt8()), UInt8(tail.vertebras.count))

        for (i, input) in tail.vertebras.enumerated() {
            let index = AEMemoryIndexForName(memory, "\(input.fullKey)".toInt8())
            recipe!.pointee.params[i] = index
        }

        AERecipeSetMemory(recipe, memory)
    }

// Core ===================================================================================
    override var key: TokenKey { tail.variableTokenKey }
    
    override func createTower(_ aetherExe: AetherExe) -> Tower { aetherExe.createMechlikeTower(tag: key.tag, core: self) }
    override func aetherExeCompleted(_ aetherExe: AetherExe) {
        whileTower = aetherExe.tower(key: tail.whileChain.key!)
        resultTower = aetherExe.tower(key: tail.resultChain.key!)
    }
    
    override func buildUpstream(tower: Tower) {
        whileTower.attach(tower)
        tail.vertebras.forEach { aetherExe.tower(key: $0.chain.key!)!.attach(tower) }
        resultTower.attach(tower)
    }
    override func renderDisplay(tower: Tower) -> String {
        if tower.variableToken.status == .deleted { fatalError() }
        if tower.variableToken.status == .invalid { return "INVALID" }
        if tower.variableToken.status == .blocked { return "BLOCKED" }
        return tail.name
    }
    override func taskCompleted(tower: Tower, askedBy: Tower) -> Bool {
        return AEMemoryLoaded(tower.memory, AEMemoryIndexForName(tower.memory, tail.variableTokenKey.tag.toInt8())) != 0
            || (askedBy !== tower && askedBy.fog == key)
    }
    override func taskBlocked(tower: Tower) -> Bool {
        resultTower.variableToken.status != .ok
    }
    override func resetTask(tower: Tower) {
        recipe = nil
        AEMemoryUnfix(tower.memory, AEMemoryIndexForName(tower.memory, tail.variableTokenKey.tag.toInt8()))
    }
    override func executeTask(tower: Tower) {
        compileRecipe()
        AEMemorySet(tower.memory, AEMemoryIndexForName(tower.memory, tail.variableTokenKey.tag.toInt8()), AEObjRecipe(recipe))
        AEMemoryFix(tower.memory, AEMemoryIndexForName(tower.memory, tail.variableTokenKey.tag.toInt8()))
        tower.variableToken.def = RecipeDef.def
    }
}

//
//  MechCore.swift
//  OoviumEngine
//
//  Created by Joe Charlier on 8/5/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import Aegean
import Foundation

class MechCore: Core {
    let mech: Mech

    var recipe: UnsafeMutablePointer<Recipe>? = nil

    var resultTower: Tower!

    init(mech: Mech) {
        self.mech = mech
    }
    deinit {
        AERecipeRelease(recipe)
    }

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
        
        return recipe
    }

//    private func compileRecipe() {
//        let memory: UnsafeMutablePointer<Memory> = AEMemoryCreateClone(aetherExe.memory)
//        AEMemoryClear(memory)
//        tail.vertebras.forEach { AEMemorySetValue(memory, aetherExe.tower(key: $0.tokenKey)!.index, 0) }
//        AERecipeRelease(recipe)
//        recipe = compile(memory: memory)
//        AERecipeSignature(recipe, AEMemoryIndexForName(memory, "\(tail.key).result".toInt8()), UInt8(tail.vertebras.count))
//
//        for (i, input) in tail.vertebras.enumerated() {
//            let index = AEMemoryIndexForName(memory, "\(input.fullKey)".toInt8())
//            recipe!.pointee.params[i] = index
//        }
//
//        AERecipeSetMemory(recipe, memory)
//    }

    private func compileRecipe() {
        let memory: UnsafeMutablePointer<Memory> = AEMemoryCreateClone(aetherExe.memory)
        AEMemoryClear(memory)
        mech.inputs.forEach { AEMemorySetValue(memory, aetherExe.tower(key: $0.tokenKey)!.index, 0) }
        AERecipeRelease(recipe)
        recipe = compile(memory: memory)
        AERecipeSignature(recipe, AEMemoryIndexForName(memory, "\(mech.key).result".toInt8()), UInt8(mech.inputs.count))

        for (i, input) in mech.inputs.enumerated() {
            let index = AEMemoryIndexForName(memory, "\(input.fullKey)".toInt8())
            recipe!.pointee.params[i] = index
        }

//        let towers: Set<Tower> = resultTower.towersDestinedFor()
//        towers.forEach { AEMemoryMarkLoaded(memory, $0.index) }
//
//        let index: mnimi = AEMemoryIndexForName(memory, variableToken.tag.toInt8())
//        AEMemorySet(memory, index, AEObjRecipe(recipe))
//        AEMemoryFix(memory, index)

        AERecipeSetMemory(recipe, memory)
    }

// Core ===================================================================================
    override var key: TokenKey { mech.mechlikeTokenKey }
    override var aetherExe: AetherExe! {
        didSet {
            resultTower = aetherExe.tower(key: mech.resultChain.key!)
        }
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
//    func renderTask(tower: Tower) -> UnsafeMutablePointer<Task>? { nil }
    override func taskCompleted(tower: Tower, askedBy: Tower) -> Bool {
        AEMemoryLoaded(tower.memory, AEMemoryIndexForName(tower.memory, mech.variableTokenKey.tag.toInt8())) != 0 || (askedBy !== tower && askedBy.web === self)
    }
    func workerBlocked(tower: Tower) -> Bool { tower.variableToken.status != .ok }
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

//
//  RecipeCore.swift
//  OoviumEngine
//
//  Created by Joe Charlier on 5/7/25.
//

import Aegean

protocol RecipeDelegate: AnyObject, VariableTokenDelegate {
    var name: String { get }
    var variableTokenKey: TokenKey { get }
    var mechlikeTokenKey: TokenKey { get }
    var params: [TokenKey] { get }
    var resultChain: Chain { get }
}

public class RecipeCore: Core {
    let delegate: RecipeDelegate

    public var recipe: UnsafeMutablePointer<Recipe>? = nil

    var resultTower: Tower!

    init(delegate: RecipeDelegate) { self.delegate = delegate }
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
        
        _ = RecipeCore.program(tasks: &tasks, tail: resultTower, memory: memory, additional: resultTower.stronglyLinked(), completed: Set<Tower>(), n: 0)
        
        let recipe = AERecipeCreate(tasks.count)!
        var i = 0
        for task in tasks {
            recipe.pointee.tasks[i] = task
            i += 1
        }
        AERecipeSetName(recipe, delegate.name.toInt8())
        
        return recipe
    }

    private func compileRecipe() {
        let memory: UnsafeMutablePointer<Memory> = AEMemoryCreateClone(citadel.memory)
        AEMemoryClear(memory)
        delegate.params.forEach { AEMemorySetValue(memory, citadel.tower(key: $0)!.index, 0) }
        AERecipeRelease(recipe)
        recipe = compile(memory: memory)
        AERecipeSignature(recipe, AEMemoryIndexForName(memory, "\(delegate.resultChain.key!.tag)".toInt8()), UInt8(delegate.params.count))

        for (i, tokenKey) in delegate.params.enumerated() {
            recipe!.pointee.params[i] = AEMemoryIndexForName(memory, "\(tokenKey.tag)".toInt8())
        }
    }

// Core ===================================================================================
    override var key: TokenKey { delegate.variableTokenKey }
    
    override func createTowerTokens(_ citadel: Citadel) -> [TowerToken] { [
        citadel.towerToken(key: delegate.variableTokenKey, delegate: delegate),
        citadel.towerToken(key: delegate.mechlikeTokenKey, delegate: delegate)
    ] }
    override func citadelCompleted(_ citadel: Citadel) {
        resultTower = citadel.tower(key: delegate.resultChain.key!)
    }

    override func buildUpstream(tower: Tower) {
        resultTower.attach(tower)
    }
    override func renderDisplay(tower: Tower) -> String {
        if tower.variableToken.status == .deleted { fatalError() }
        if tower.variableToken.status == .invalid { return "INVALID" }
        if tower.variableToken.status == .blocked { return "BLOCKED" }
        return delegate.name
    }
    override func taskCompleted(tower: Tower, askedBy: Tower) -> Bool {
        AEMemoryLoaded(tower.memory, AEMemoryIndexForName(tower.memory, delegate.variableTokenKey.tag.toInt8())) != 0
            || (askedBy !== tower && askedBy.fog == delegate.mechlikeTokenKey)
    }
    override func taskBlocked(tower: Tower) -> Bool {
        resultTower.variableToken.status != .ok
    }
    override func resetTask(tower: Tower) {
        recipe = nil
        AEMemoryUnfix(tower.memory, AEMemoryIndexForName(tower.memory, delegate.variableTokenKey.tag.toInt8()))
    }
    override func executeTask(tower: Tower) {
        compileRecipe()
        AEMemorySet(tower.memory, AEMemoryIndexForName(tower.memory, delegate.variableTokenKey.tag.toInt8()), AEObjRecipe(recipe))
        AEMemoryFix(tower.memory, AEMemoryIndexForName(tower.memory, delegate.variableTokenKey.tag.toInt8()))
        tower.variableToken.def = RecipeDef.def
    }
}

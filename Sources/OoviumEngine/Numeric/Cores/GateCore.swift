//
//  GateCore.swift
//  OoviumEngine
//
//  Created by Joe Charlier on 8/5/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import Aegean
import Foundation

class GateCore: Core {
    let gate: Gate
    
    var ifTower: Tower!
    var thenTower: Tower!
    var elseTower: Tower!
    
    init(gate: Gate) { self.gate = gate }
    
// Core ============================================================================================
    override var key: TokenKey { gate.resultKey }
    override var fog: TokenKey? { ifTower.fog ?? thenTower.fog ?? elseTower.fog }

    override func aetherExeCompleted(_ aetherExe: AetherExe) {
        ifTower = aetherExe.tower(key: gate.ifChain.key!)
        thenTower = aetherExe.tower(key: gate.thenChain.key!)
        elseTower = aetherExe.tower(key: gate.elseChain.key!)
        
        ifTower.gateTo = tower
        ifTower.thenTo = thenTower
        ifTower.elseTo = elseTower
        thenTower.gate = ifTower
        elseTower.gate = ifTower
        
        let funnel = Funnel(options: [thenTower, elseTower], spout: tower)
        thenTower.funnel = funnel
        elseTower.funnel = funnel
    }
    
    override func buildUpstream(tower: Tower) {
        ifTower.attach(tower)
        thenTower.attach(tower)
        elseTower.attach(tower)
    }
    override func renderDisplay(tower: Tower) -> String { "if" }
    override func renderTask(tower: Tower) -> UnsafeMutablePointer<Task>? {
        let resultName = tower.variableToken.tag
        let task: UnsafeMutablePointer<Task> = AETaskCreateFork(ifTower.index, thenTower.index, elseTower.index, tower.index)
        AETaskSetLabels(task, resultName.toInt8(), "\(resultName) = ~".toInt8())
        return task
    }
    override func taskCompleted(tower: Tower, askedBy: Tower) -> Bool {
        AEMemoryLoaded(tower.memory, tower.index) != 0
    }
    override func taskBlocked(tower: Tower) -> Bool {
        [ifTower,thenTower,elseTower].contains {$0.variableToken.status != .ok}
    }
    override func resetTask(tower: Tower) {
        AEMemoryUnfix(tower.memory, tower.index)
    }
    override func executeTask(tower: Tower) {
        AETaskExecute(tower.task, tower.memory)
        AEMemoryFix(tower.memory, tower.index)
//        tower.variableToken.label = Oovium.format(value: tower.value)
    }
}

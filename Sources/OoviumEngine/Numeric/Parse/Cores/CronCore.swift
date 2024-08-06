//
//  CronCore.swift
//  OoviumEngine
//
//  Created by Joe Charlier on 8/5/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import Aegean
import Foundation

class CronCore: Core {
    let cron: Cron
    
    public var t: Double = 0
    public var dt: Double = 1
    public var sealed: Bool = true
    
    var startTower: Tower!
    var stopTower: Tower!
    var stepsTower: Tower!
    var rateTower: Tower!
    var deltaTower: Tower!
    var whileTower: Tower!
    
    init(cron: Cron) {
        self.cron = cron
    }
    
    public func reset() {
        if cron.endMode == .stop || cron.endMode == .repeat || cron.endMode == .bounce {
            dt = (stopTower.value - startTower.value)/(stepsTower.value-1)
        } else {
            dt = deltaTower.value
        }
        t = startTower.value
        sealed = true
    }
    public func increment() -> Bool {
        if sealed {
            sealed = false
        } else if (cron.endMode == .stop && t+dt > stopTower.value) || (cron.endMode == .while && whileTower.value == 0) {
            t = startTower.value
        } else {
            t += dt
        }
        tower.trigger()
        switch cron.endMode {
            case .stop:
                if t+dt > stopTower.value { return true }
            case .repeat:
                if t+dt > stopTower.value {
                    t = startTower.value
                    sealed = true
                    return false
                }
            case .bounce:
                if t+dt > stopTower.value || t+dt < startTower.value {dt = -dt}
            case .endless: break;
            case .while:
                if whileTower.value == 0 {return true}
        }
        return false
    }
    
// Core ===================================================================================
    override var aetherExe: AetherExe! {
        didSet {}
    }
    override func renderDisplay(tower: Tower) -> String {
        tower.obje.display
    }
    override func taskCompleted(tower: Tower, askedBy: Tower) -> Bool {
        AEMemoryLoaded(tower.memory, tower.index) != 0
    }
    override func resetTask(tower: Tower) {
        AEMemoryUnfix(tower.memory, tower.index)
    }
    override func executeTask(tower: Tower) {
        AEMemorySetValue(tower.memory, tower.index, t)
        AEMemoryFix(tower.memory, tower.index)
//        tower.variableToken.value = tower.obje.display
    }

}

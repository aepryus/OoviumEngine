//
//  HeaderCore.swift
//  OoviumEngine
//
//  Created by Joe Charlier on 10/6/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import Aegean

class HeaderCore: Core, VariableTokenDelegate {
    let column: Column
    
    init(column: Column) {
        self.column = column
    }
    
    var grid: Grid { column.grid }
    
// Core ============================================================================================
    override var key: TokenKey { column.headerTokenKey }
    
    override func createTower(_ aetherExe: AetherExe) -> Tower { aetherExe.createHeaderTower(tag: key.tag, core: self, tokenDelegate: self) }

    override func buildUpstream(tower: Tower) {}
    override func renderDisplay(tower: Tower) -> String { "---" }
    override func renderTask(tower: Tower) -> UnsafeMutablePointer<Task>? { nil }
    override func taskCompleted(tower: Tower, askedBy: Tower) -> Bool { true }
    override func resetTask(tower: Tower) {}
    override func executeTask(tower: Tower) {}
    
// VariableTokenDelegate ===========================================================================
    var alias: String? { column.name }
}

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
    
    public var tokens: [Token] = []
    
    init(column: Column) {
        self.column = column
    }
    
    var grid: Grid { column.grid }
    
    public override var tokensDisplay: String {
        tokens.map({ $0.display }).joined()
    }
    
    func loadTokens() {
        guard let aetherExe else { return }
        tokens = column.chain.tokenKeys.map({ (key: TokenKey) in aetherExe.token(key: key) })
    }

// Core ============================================================================================
    override var key: TokenKey { column.headerTokenKey }
    
//    override func createTower(_ aetherExe: AetherExe) -> Tower { aetherExe.createHeaderTower(tag: key.tag, core: self, tokenDelegate: self) }
    override func createTowerTokens(_ aetherExe: AetherExe) -> [TowerToken] { [aetherExe.towerToken(key: key, delegate: self)] }
    override func aetherExeCompleted(_ aetherExe: AetherExe) { loadTokens() }

    override func buildUpstream(tower: Tower) {
        aetherExe.nukeUpstream(key: column.chain.key!)
        tokens.compactMap { $0 as? TowerToken }.forEach {
            $0.tower.attach(tower)
        }
    }
    override func renderDisplay(tower: Tower) -> String { "---" }
    override func renderTask(tower: Tower) -> UnsafeMutablePointer<Task>? { nil }
    override func taskCompleted(tower: Tower, askedBy: Tower) -> Bool { true }
    override func resetTask(tower: Tower) {
        loadTokens()
    }
    override func executeTask(tower: Tower) {}
    
// VariableTokenDelegate ===========================================================================
    var alias: String? { column.name }
}

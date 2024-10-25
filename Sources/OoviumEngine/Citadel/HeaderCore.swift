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
        guard let citadel else { return }
        tokens = column.chain.tokenKeys.map({ (key: TokenKey) in citadel.token(key: key) })
    }

// Core ============================================================================================
    override var key: TokenKey { column.headerTokenKey }
    
//    override func createTower(_ citadel: Citadel) -> Tower { citadel.createHeaderTower(tag: key.tag, core: self, tokenDelegate: self) }
    override func createTowerTokens(_ citadel: Citadel) -> [TowerToken] { [citadel.towerToken(key: key, delegate: self)] }
    override func citadelCompleted(_ citadel: Citadel) { loadTokens() }

    override func buildUpstream(tower: Tower) {
        citadel.nukeUpstream(key: column.chain.key!)
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

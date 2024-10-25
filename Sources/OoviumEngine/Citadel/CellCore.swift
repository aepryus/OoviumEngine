//
//  CellCore.swift
//  OoviumEngine
//
//  Created by Joe Charlier on 10/15/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//


class CellCore: ChainCore {
    let cell: Cell
    
    init(cell: Cell, chain: Chain, fog: TokenKey? = nil, variableTokenDelegate: VariableTokenDelegate? = nil) {
        self.cell = cell
        super.init(chain: chain, fog: fog, variableTokenDelegate: variableTokenDelegate)
    }
    
// ChainCore =======================================================================================
    override func buildUpstream(tower: Tower) {
        super.buildUpstream(tower: tower)
        
        guard cell.column.calculated else { return }
        
        let headerTower: Tower = aetherExe.tower(key: cell.column.chain.key!)!
        tower.attach(headerTower)
    }
}

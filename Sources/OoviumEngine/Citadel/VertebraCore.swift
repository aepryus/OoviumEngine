//
//  VertebraCore.swift
//  OoviumEngine
//
//  Created by Joe Charlier on 8/6/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import Foundation

class VertebraCore: Core {
    let vertebra: Vertebra
    
    init(vertebra: Vertebra) { self.vertebra = vertebra }

// Core ============================================================================================
    override var key: TokenKey { vertebra.tokenKey }
    override var fog: TokenKey? { vertebra.tail.mechlikeTokenKey }

    override func createTowerTokens(_ aetherExe: AetherExe) -> [TowerToken] { [aetherExe.towerToken(key: key, delegate: vertebra)] }
    override func renderDisplay(tower: Tower) -> String { vertebra.name }
}

//
//  VertebraCore.swift
//  OoviumEngine
//
//  Created by Joe Charlier on 8/6/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import Foundation

class VertebraCore: Core, VariableTokenDelegate {
    let vertebra: Vertebra
    
    init(vertebra: Vertebra) { self.vertebra = vertebra }

// Core ============================================================================================
//    override func createTower(_ aetherExe: AetherExe) -> Tower { aetherExe.createTower(key: key, core: self, variableTokenDelegate: self) }

    override var key: TokenKey { vertebra.tokenKey }
    override var fog: TokenKey? { vertebra.tail.mechlikeTokenKey }

    override func renderDisplay(tower: Tower) -> String { vertebra.name }
    
// VariableTokenDelegate ===========================================================================
    public var alias: String? { vertebra.name }
}

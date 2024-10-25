//
//  InputCore.swift
//  OoviumEngine
//
//  Created by Joe Charlier on 8/5/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import Foundation

class InputCore: Core {
    let input: Input
    
    init(input: Input) { self.input = input }
    
// Core ============================================================================================
    override var key: TokenKey { input.tokenKey }
    override var fog: TokenKey? { input.mech.mechlikeTokenKey }

    override func createTowerTokens(_ aetherExe: AetherExe) -> [TowerToken] { [aetherExe.towerToken(key: key, delegate: input)] }
    override func renderDisplay(tower: Tower) -> String { input.name }
}

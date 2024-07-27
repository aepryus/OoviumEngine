//
//  SyainState.swift
//  OoviumEngine
//
//  Created by Joe Charlier on 7/24/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import Foundation

class SyainState: TowerDelegate {
    let syain: Syain
    
    var tower: Tower?

    init(syain: Syain) { self.syain = syain }
    
// Computed ========================================================================================
    var key: String? { syain.key }    
}

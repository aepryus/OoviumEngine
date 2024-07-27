//
//  Syain.swift
//  OoviumEngine
//
//  Created by Joe Charlier on 7/24/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import Foundation

class Syain {
    let key: String
    
    private var state: SyainState!

// Inits ===========================================================================================
    public init(key: String) { self.key = key }
    
// Methods =========================================================================================
    func load(state: SyainState) { self.state = state }
}

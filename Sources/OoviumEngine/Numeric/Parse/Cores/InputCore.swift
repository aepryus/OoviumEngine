//
//  InputCore.swift
//  OoviumEngine
//
//  Created by Joe Charlier on 8/5/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import Foundation

class InputCore: Core, VariableTokenDelegate {
    let input: Input
    
    init(input: Input) {
        self.input = input
    }
    
// Core ===================================================================================
    override var key: TokenKey { input.tokenKey }

    override func renderDisplay(tower: Tower) -> String { input.name }
    
// VariableTokenDelegate ===========================================================================
    public var alias: String? { input.name }
}

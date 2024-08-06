//
//  File.swift
//  
//
//  Created by Joe Charlier on 8/6/24.
//

import Foundation

class VertebraCore: Core, VariableTokenDelegate {
    let vertebra: Vertebra
    
    init(vertebra: Vertebra) {
        self.vertebra = vertebra
    }

// Core ============================================================================================
    override var key: TokenKey { vertebra.tokenKey }
    
    override func renderDisplay(tower: Tower) -> String { vertebra.name }
    
// VariableTokenDelegate ===========================================================================
    public var alias: String? { vertebra.name }
}

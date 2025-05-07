//
//  ParameterCore.swift
//  OoviumEngine
//
//  Created by Joe Charlier on 5/6/25.
//

import Foundation

protocol ParameterDelegate: AnyObject, VariableTokenDelegate {
    var tokenKey: TokenKey { get }
    var fogKey: TokenKey? { get }
    var name: String { get }
}

class StaticParameter: ParameterDelegate {
    let tokenKey: TokenKey
    let fogKey: TokenKey?
    let name: String
    
    init(tokenKey: TokenKey, fogKey: TokenKey? = nil, name: String) {
        self.tokenKey = tokenKey
        self.fogKey = fogKey
        self.name = name
    }
    
// VariableTokenDelegate ===========================================================================
    var alias: String? { name }
}

class ParameterCore: Core {
    let parameter: ParameterDelegate
    
    init(parameter: ParameterDelegate) { self.parameter = parameter }
    
// Core ============================================================================================
    override var key: TokenKey { parameter.tokenKey }
    override var fog: TokenKey? { parameter.fogKey }

    override func createTowerTokens(_ citadel: Citadel) -> [TowerToken] { [citadel.towerToken(key: key, delegate: parameter)] }
    override func renderDisplay(tower: Tower) -> String { parameter.name }
}

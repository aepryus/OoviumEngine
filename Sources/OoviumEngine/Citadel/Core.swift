//
//  GateCore.swift
//  OoviumEngine
//
//  Created by Joe Charlier on 8/5/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import Aegean
import Foundation

public class Core: Hashable {
    var key: TokenKey { fatalError() }

    var citadel: Citadel! { didSet { citadelCompleted(citadel) } }
    var tower: Tower!
    var fog: TokenKey? { nil }
    var isFogFirewall: Bool { false }
    
    public var tokensDisplay: String { "not implemented yet" }
    public var valueDisplay: String { "not implemented yet" }
    public var naturalDisplay: String { "not implemented yet" }

    func createTowerTokens(_ citadel: Citadel) -> [TowerToken] { [citadel.towerToken(key: key)] }
    func citadelCompleted(_ citadel: Citadel) {}
    
    func buildUpstream(tower: Tower) {}
    func renderDisplay(tower: Tower) -> String { "---" }
    func renderTask(tower: Tower) -> UnsafeMutablePointer<Task>? { nil }
    func taskCompleted(tower: Tower, askedBy: Tower) -> Bool { true }
    func taskBlocked(tower: Tower) -> Bool { false }
    func resetTask(tower: Tower) {}
    func executeTask(tower: Tower) {}
    
// Hashable ========================================================================================
    public static func == (lhs: Core, rhs: Core) -> Bool { lhs.key == rhs.key }
    public func hash(into hasher: inout Hasher) { hasher.combine(key.description) }
}

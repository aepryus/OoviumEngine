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

    var aetherExe: AetherExe! { didSet { aetherExeCompleted(aetherExe) } }
    var tower: Tower!
    var fog: TokenKey? { nil }
    var isFogFirewall: Bool { false }
    
    public var tokensDisplay: String { "not implemented yet" }
    public var valueDisplay: String { "not implemented yet" }
    public var naturalDisplay: String { "not implemented yet" }

//    func createTower(_ aetherExe: AetherExe) -> Tower { aetherExe.createTower(key: key, core: self) }
    func createTowerTokens(_ aetherExe: AetherExe) -> [TowerToken] { [aetherExe.variableToken(tag: key.tag)] }
    func aetherExeCompleted(_ aetherExe: AetherExe) {}
    
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

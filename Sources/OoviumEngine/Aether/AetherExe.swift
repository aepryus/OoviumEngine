//
//  AetherExe.swift
//  OoviumEngine
//
//  Created by Joe Charlier on 7/6/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import Acheron
import Aegean
import Foundation

public class AetherExe {
    unowned let aether: Aether
    
    private var tokens: [TokenKey:TowerToken] = [:]
    private var towers: [TowerToken:Tower] = [:]
    public private(set) var memory: UnsafeMutablePointer<Memory> = AEMemoryCreate(0)
    
    var chainExes: [TokenKey:ChainExe] = [:]

    init(aether: Aether) {
        self.aether = aether
        
        let chains: [Chain] = aether.aexels.flatMap({ $0.chains })
        
        chains.forEach { (chain: Chain) in
            guard let key = chain.key else { return }
            let chainExe: ChainExe = ChainExe(chain: chain)
            chainExe.tower = createTower(key: key, towerDelegate: chainExe)
            chainExes[key] = chainExe
        }
        chainExes.values.forEach { $0.buildTokens(aetherExe: self) }
        towers.values.forEach { $0.buildStream() }
        buildMemory()
        Tower.evaluate(towers: Set(towers.values))
    }

    deinit { AEMemoryRelease(memory) }

// Computed ========================================================================================
//    private var mechlikeTowers: [Tower] { aether.aexels.filter({ $0 is Mechlike }).flatMap({ $0.towers }) }
//    private var webTowers: [Tower] { aether.aexels.flatMap({ $0.towers }).filter({ $0.web != nil }) }
    
// TokenKeys =======================================================================================
    public func token(key: TokenKey) -> Token { tokens[key]! }
    public func chainExe(key: TokenKey) -> ChainExe { chainExes[key]! }
    public func tokenDisplay(key: TokenKey) -> String { chainExes[key]!.tokensDisplay }
    public func valueDisplay(key: TokenKey) -> String { chainExes[key]!.valueDisplay }
    public func naturalDisplay(key: TokenKey) -> String { chainExes[key]!.naturalDisplay }

// Methods =========================================================================================
    func add(chain: Chain) {
        let state: ChainExe = ChainExe(chain: chain)
        if let key: TokenKey = chain.key { state.tower = createTower(key: key, towerDelegate: state) }
//        chain.load(state: state)
        
        buildMemory()
//        evaluate()
    }
    func remove(chain: Chain) {}
    
    func token(key: TokenKey) -> Token? { tokens[key] }
    func variableToken(tag: String) -> VariableToken {
        let key: TokenKey = TokenKey(code: .va, tag: tag)
        if let token: VariableToken = tokens[key] as? VariableToken { return token }
        let token: VariableToken = VariableToken(tag: tag)
        tokens[key] = token
        return token
    }
    func mechlikeToken(tag: String) -> MechlikeToken {
        let key: TokenKey = TokenKey(code: .va, tag: tag)
        if let token: MechlikeToken = tokens[key] as? MechlikeToken { return token }
        let token: MechlikeToken = MechlikeToken(tag: tag)
        tokens[key] = token
        return token
    }
    func tower(key: TokenKey) -> Tower? {
        guard let token: TowerToken = tokens[key] else { return nil }
        return towers[token]
    }
    
//    public func paste(array: [[String:Any]]) -> [Aexel] {
//        print(array.toJSON())
//        var substitutions: [String:Token] = [:]
//        var aexels: [Aexel] = []
//        var towers: Set<Tower> = Set<Tower>()
//        let tempAether: Aether = Aether()
//        array.forEach { (attributes: [String:Any]) in
//            var attributes = attributes
//            var aexel: Aexel = Loom.domain(attributes: attributes, parent: tempAether) as! Aexel
//            let fromTokens: [Token] = aexel.towers.sorted(by: { $0.name < $1.name }).map({ $0.variableToken })
//            let oldNo: Int = aexel.no
//            let newNo: Int = state.nos.increment(key: aexel.type)
//            print("\(oldNo) => \(newNo)")
//            attributes["no"] = newNo
//            aexel = Loom.domain(attributes: attributes, parent: self, replicate: true) as! Aexel
//            aexel.x += 25
//            aexel.y += 25
//            let toTokens: [Token] = aexel.towers.sorted(by: { $0.name < $1.name }).map({ $0.variableToken })
//            add(aexel)
//            self.aexels.append(aexel)
//            towers.formUnion(aexel.towers)
//            for i in 0..<fromTokens.count { substitutions[fromTokens[i].key] = toTokens[i] }
//            aexels.append(aexel)
//        }
//
//        substitutions.forEach { print("Substituting: \($0.key) -> \($0.value.key)") }
//
//        aexels.flatMap({ $0.chains }).forEach({
//            $0.buildTokens(aether: self)
//            $0.exchange(substitutions: substitutions)
//        })
//
//        towers.forEach { $0.buildStream() }
//        state.buildMemory()
//        Tower.evaluate(towers: towers)
//
//        state = AetherExe(aether: self)
//
//        return aexels
//    }

    
// Evaluate ========================================================================================
    public func buildMemory() {
        var vars: [String] = ["k"]
        vars += tokens.values.filter { $0.code == .va && $0.status != .deleted }.map { $0.tag }
        vars.sort(by: { $0.uppercased() < $1.uppercased() })

        let oldMemory: UnsafeMutablePointer<Memory> = memory
        memory = AEMemoryCreate(vars.count)
        vars.enumerated().forEach { AEMemorySetName(memory, UInt16($0), $1.toInt8()) }
        AEMemoryLoad(memory, oldMemory)
        AEMemoryRelease(oldMemory)
        
//        Tower.evaluate(towers: Set<Tower>(webTowers))
    }
    
// Towers ==========================================================================================
    public func destroy(towers: [Tower]) {
        var affected: Set<Tower> = Set<Tower>()
        towers.forEach { affected.formUnion($0.allDownstream()) }
        affected.subtract(towers)
        
        towers.forEach { (tower: Tower) in
            tower.variableToken.status = .deleted
            tower.abstract()
            self.towers[tower.variableToken] = nil
            self.tokens[tower.variableToken.key] = nil
            if let mechlikeToken = tower.mechlikeToken {
                self.towers[mechlikeToken] = nil
                self.tokens[mechlikeToken.key] = nil
            }
        }
        
        Tower.evaluate(towers: affected)
        buildMemory()
    }
    public func destroy(tower: Tower) { destroy(towers: [tower]) }
    func createTower(key: TokenKey, towerDelegate: TowerDelegate, tokenDelegate: VariableTokenDelegate? = nil) -> Tower {
        let token = VariableToken(tag: key.tag, delegate: tokenDelegate)
        tokens[token.key] = token
        let tower = Tower(aetherExe: self, token: token, delegate: towerDelegate)
        towers[token] = tower
        token.tower = tower
        return tower
    }
    func createMechlikeTower(tag: String, towerDelegate: TowerDelegate, tokenDelegate: VariableTokenDelegate? = nil) -> Tower {
        let variableToken = VariableToken(tag: tag, delegate: tokenDelegate)
        tokens[variableToken.key] = variableToken
        let tower = Tower(aetherExe: self, token: variableToken, delegate: towerDelegate)
        let mechlikeToken = MechlikeToken(tower: tower, tag: tag, delegate: tokenDelegate)
        tokens[mechlikeToken.key] = mechlikeToken
        tower.mechlikeToken = mechlikeToken
        towers[variableToken] = tower
        towers[mechlikeToken] = tower
        return tower
    }
    public func mechlikeToken(tag: String) -> MechlikeToken? { tokens[TokenKey(code: .ml, tag: tag)] as? MechlikeToken }
    func createColumnTower(tag: String, towerDelegate: TowerDelegate, tokenDelegate: VariableTokenDelegate? = nil) -> Tower {
        let token = ColumnToken(tag: tag, delegate: tokenDelegate)
        tokens[token.key] = token
        let tower = Tower(aetherExe: self, token: token, delegate: towerDelegate)
        towers[token] = tower
        return tower
    }
}

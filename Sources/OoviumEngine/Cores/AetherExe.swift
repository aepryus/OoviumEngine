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
    private var towers: [Tower] = []
    private var towerLookup: [TowerToken:Tower] = [:]
    public private(set) var memory: UnsafeMutablePointer<Memory> = AEMemoryCreate(0)
    
    var cores: [TokenKey:Core] = [:]

    init(aether: Aether) {
        self.aether = aether
        build()
    }
    deinit { AEMemoryRelease(memory) }

// Computed ========================================================================================
    private func tower(for token: TowerToken) -> Tower { towerLookup[token]! }
    private func token(for key: TokenKey) -> TowerToken { tokens[key]! }
    private func tower(for key: TokenKey) -> Tower { tower(for: token(for: key)) }

// TokenKeys =======================================================================================
    public func chainCore(key: TokenKey) -> ChainCore { (cores[key] as! ChainCore) }
    public func tokenDisplay(key: TokenKey) -> String { cores[key]!.tokensDisplay }
    public func valueDisplay(key: TokenKey) -> String { cores[key]!.valueDisplay }
    public func naturalDisplay(key: TokenKey) -> String { cores[key]!.naturalDisplay }
    
// Private =========================================================================================
    private func reset() {
        tokens = [:]
        towers = []
        towerLookup = [:]
        AEMemoryRelease(memory)
        memory = AEMemoryCreate(0)
    }
    private func build() {
        plugIn(aexons: aether.aexels)
        buildMemory()
        Tower.evaluate(towers: Set(towers))
    }

// Methods =========================================================================================
    public func notifyListeners() { Tower.notifyListeners(towers: Set<Tower>(towers)) }
    
    public func canBeAdded(thisKey: TokenKey, to thatKey: TokenKey) -> Bool {
        let that: Tower = towerLookup[tokens[thatKey]!]!
        guard let thisToken: TowerToken = tokens[thisKey] else { return true }
        let this: Tower = towerLookup[thisToken]!
        if that.downstream(contains: this) { return false }
        guard let thisFog: TokenKey = this.fog, let thatFog: TokenKey = that.fog else { return true }
        return thisFog == thatFog
    }
    public func increment(key: TokenKey, dependenceOn: TokenKey) {
        let keyTower: Tower = tower(for: key)
        let dependsOnTower: Tower = tower(for: dependenceOn)
        keyTower.upstream.increment(tower: dependsOnTower)
        dependsOnTower.downstream.increment(tower: keyTower)
    }
    public func decrement(key: TokenKey, dependenceOn: TokenKey) {
        let keyTower: Tower = tower(for: key)
        let dependsOnTower: Tower = tower(for: dependenceOn)
        keyTower.upstream.decrement(tower: dependsOnTower)
        dependsOnTower.downstream.decrement(tower: keyTower)
    }
    
    public func nukable(keys: [TokenKey]) -> Bool {
        let towers: Set<Tower> = Set(keys.map({ tower(key: $0)! }))
        let downstream: Set<Tower> = Set(towers.flatMap({ $0.downstream.towersSet }))
        return downstream.isSubset(of: towers)
    }
    private func nukeUpstrean(tower: Tower) {
        tower.upstream.forEach { $0.downstream.nuke(tower: tower) }
        tower.upstream.nukeAll()
    }
    public func nukeUpstream(key: TokenKey) { nukeUpstrean(tower: tower(for: key)) }
    public func nuke(key: TokenKey) -> Bool {
        guard let token: TowerToken = tokens[key],
              let tower: Tower = towerLookup[token],
              tower.downstream.count == 0
        else { return false }

        nukeUpstrean(tower: tower)
        towers.remove(object: tower)
        towerLookup[token] = nil
        tokens[key] = nil

        return true
    }
    public func nuke(keys: [TokenKey]) -> Bool {
        let towers: Set<Tower> = Set(keys.map({ tower(key: $0)! }))
        let downstream: Set<Tower> = Set(towers.flatMap({ $0.downstream.towersSet }))
        
        guard downstream.isSubset(of: towers) else { return false }
        
        keys.forEach { _ = nuke(key: $0) }
        
        return true
    }

    public func token(key: TokenKey) -> Token { tokens[key] ?? Token.token(key: key) ?? .zero }
    public func value(key: TokenKey) -> String? { (token(key: key) as? VariableToken)?.value }
    func variableToken(tag: String, delegate: VariableTokenDelegate? = nil) -> VariableToken {
        let key: TokenKey = TokenKey(code: .va, tag: tag)
        if let token: VariableToken = tokens[key] as? VariableToken { return token }
        let token: VariableToken = VariableToken(tag: tag, delegate: delegate)
        tokens[key] = token
        return token
    }
    func mechlikeToken(tag: String, delegate: VariableTokenDelegate? = nil) -> MechlikeToken {
        let key: TokenKey = TokenKey(code: .va, tag: tag)
        if let token: MechlikeToken = tokens[key] as? MechlikeToken { return token }
        let token: MechlikeToken = MechlikeToken(tag: tag, delegate: delegate)
        tokens[key] = token
        return token
    }
    func columnToken(tag: String) -> ColumnToken {
        let key: TokenKey = TokenKey(code: .cl, tag: tag)
        if let token: ColumnToken = tokens[key] as? ColumnToken { return token }
        let token: ColumnToken = ColumnToken(tag: tag)
        tokens[key] = token
        return token
    }

    public func tower(key: TokenKey) -> Tower? {
        guard let token: TowerToken = tokens[key] else { return nil }
        return towerLookup[token]
    }
    
    private func harvest(aexon: Aexon) -> [Tower] {
        var towers: [Tower] = []
        aexon.createCores().forEach { (core: Core) in
            core.tower = core.createTower(self)
            let towerTokens: [TowerToken] = core.createTowerTokens(self)
            towerTokens.forEach { (token: TowerToken) in
                token.tower = core.tower
                tokens[token.key] = token
                towerLookup[token] = core.tower
            }
            towers.append(core.tower)
            cores[core.key] = core
        }
        return towers
    }
    public func plugIn(aexons: [Aexon]) {
        let towers: [Tower] = aexons.flatMap({ harvest(aexon: $0) })
        cores.values.forEach { $0.aetherExe = self }
        towers.forEach { $0.buildStream() }
    }
    public func plugIn(aexon: Aexon) { plugIn(aexons: [aexon]) }
    
    public func inAFog(key: TokenKey) -> Bool { tower(key: key)?.fog != nil }
    
    public func paste(array: [[String:Any]]) -> [Aexel] {
        print(array.toJSON())
        var substitutions: [TokenKey:TokenKey] = [:]
        var aexels: [Aexel] = []
        let tempAether: Aether = Aether()
        array.forEach { (attributes: [String:Any]) in
            var attributes = attributes
            var aexel: Aexel = Loom.domain(attributes: attributes, parent: tempAether) as! Aexel
            let fromKeys: [TokenKey] = aexel.tokenKeys.sorted(by: { $0.description < $1.description })
            let oldNo: Int = aexel.no
            let newNo: Int = aether.newNo(type: aexel.type)
            print("\(oldNo) => \(newNo)")
            attributes["no"] = newNo
            aexel = Loom.domain(attributes: attributes, parent: aether, replicate: true) as! Aexel
            aexel.x += 25
            aexel.y += 25
            let toKeys: [TokenKey] = aexel.tokenKeys.sorted(by: { $0.description < $1.description })
            aether.addAexel(aexel)
            for i in 0..<fromKeys.count { substitutions[fromKeys[i]] = toKeys[i] }
            aexels.append(aexel)
        }

        substitutions.forEach { print("Substituting: \($0.key) -> \($0.value)") }
        let chains: [Chain] = aexels.flatMap({ $0.chains })
        chains.forEach({
            $0.key = substitutions[$0.key!] ?? $0.key
            $0.tokenKeys = $0.tokenKeys.map({ substitutions[$0] ?? $0 })
        })
        
        reset()
        build()

        return aexels
    }
    
    public func trigger(keys: [TokenKey]) {
        let towersArray: [Tower] = keys.map({ tower(key: $0)! })
        var towersSet: Set<Tower> = Set()
        towersArray.forEach { towersSet.formUnion($0.allDownstream()) }
        buildMemory()
        Tower.evaluate(towers: towersSet)
    }
    public func trigger(key: TokenKey) { trigger(keys: [key]) }

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
    }
    
// Towers ==========================================================================================
    public func destroy(towers: [Tower]) {
        var affected: Set<Tower> = Set<Tower>()
        towers.forEach { affected.formUnion($0.allDownstream()) }
        affected.subtract(towers)
        
        towers.forEach { (tower: Tower) in
            tower.variableToken.status = .deleted
            tower.abstract()
            self.towerLookup[tower.variableToken] = nil
            self.tokens[tower.variableToken.key] = nil
            if let mechlikeToken = tower.mechlikeToken {
                self.towerLookup[mechlikeToken] = nil
                self.tokens[mechlikeToken.key] = nil
            }
        }
        
        Tower.evaluate(towers: affected)
        buildMemory()
    }
    public func destroy(tower: Tower) { destroy(towers: [tower]) }
    func createTower(key: TokenKey, core: Core, variableTokenDelegate: VariableTokenDelegate? = nil) -> Tower {
        let token = VariableToken(tag: key.tag, delegate: variableTokenDelegate)
        tokens[token.key] = token
        let tower = Tower(aetherExe: self, token: token, core: core)
        towers.append(tower)
        towerLookup[token] = tower
        token.tower = tower
        return tower
    }
    func createMechlikeTower(tag: String, core: Core, tokenDelegate: VariableTokenDelegate? = nil) -> Tower {
        let variableToken = VariableToken(tag: tag, delegate: tokenDelegate)
        tokens[variableToken.key] = variableToken
        let tower = Tower(aetherExe: self, token: variableToken, core: core)
        towers.append(tower)
        let mechlikeToken = MechlikeToken(tower: tower, tag: tag, delegate: tokenDelegate)
        tokens[mechlikeToken.key] = mechlikeToken
        tower.mechlikeToken = mechlikeToken
        towerLookup[variableToken] = tower
        towerLookup[mechlikeToken] = tower
        return tower
    }
    public func mechlikeToken(tag: String) -> MechlikeToken? { tokens[TokenKey(code: .ml, tag: tag)] as? MechlikeToken }
    
    func createHeaderTower(tag: String, core: Core, tokenDelegate: VariableTokenDelegate? = nil) -> Tower {
        let token = ColumnToken(tag: tag, delegate: tokenDelegate)
        tokens[token.key] = token
        let tower = Tower(aetherExe: self, token: token, core: core)
        towers.append(tower)
        towerLookup[token] = tower
        return tower
    }
    
    public func printTowers() { Tower.printTowers(towers) }
}

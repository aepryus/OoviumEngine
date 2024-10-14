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
        
        aether.aexels.forEach({ add(aexon: $0) })

        // Combined ? ======================
        cores.values.forEach { $0.aetherExe = self }
        towers.forEach { $0.buildStream() }
        // =================================
        
        buildMemory()
        Tower.evaluate(towers: Set(towers))
    }
    deinit { AEMemoryRelease(memory) }

// Computed ========================================================================================
//    private var mechlikeTowers: [Tower] { aether.aexels.filter({ $0 is Mechlike }).flatMap({ $0.towers }) }
//    private var webTowers: [Tower] { aether.aexels.flatMap({ $0.towers }).filter({ $0.web != nil }) }
    
    private func tower(for token: TowerToken) -> Tower { towerLookup[token]! }
    private func token(for key: TokenKey) -> TowerToken { tokens[key]! }
    private func tower(for key: TokenKey) -> Tower { tower(for: token(for: key)) }

// TokenKeys =======================================================================================
    public func chainCore(key: TokenKey) -> ChainCore { (cores[key] as! ChainCore) }
    public func tokenDisplay(key: TokenKey) -> String { cores[key]!.tokensDisplay }
    public func valueDisplay(key: TokenKey) -> String { cores[key]!.valueDisplay }
    public func naturalDisplay(key: TokenKey) -> String { cores[key]!.naturalDisplay }

// Methods =========================================================================================
    public func notifyListeners() { Tower.notifyListeners(towers: Set<Tower>(towers)) }
    
    public func canBeAdded(thisKey: TokenKey, to thatKey: TokenKey) -> Bool {
        let that: Tower = towerLookup[tokens[thatKey]!]!
        guard let thisToken: TowerToken = tokens[thisKey] else { return true }
        let this: Tower = towerLookup[thisToken]!
        if this.downstream(contains: that) { return false }
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
    public func nuke(key: TokenKey) {
        let tower: Tower = tower(for: key)
        tower.upstream.forEach { $0.downstream.nuke(tower: tower) }
        tower.downstream.forEach { $0.upstream.nuke(tower: tower) }
    }
    public func nuke(keys: [TokenKey]) { keys.forEach { nuke(key: $0) } }
    
    func add(chain: Chain) {
//        let state: ChainCore = ChainCore(chain: chain)
//        if let key: TokenKey = chain.key { state.tower = createTower(key: key, towerDelegate: state) }
//        chain.load(state: state)
        
        buildMemory()
//        evaluate()
    }
    func remove(chain: Chain) {}
    
    public func token(key: TokenKey) -> Token { tokens[key] ?? Token.token(key: key) ?? .zero }
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
    public func tower(key: TokenKey) -> Tower? {
        guard let token: TowerToken = tokens[key] else { return nil }
        return towerLookup[token]
    }
    
    public func add(aexon: Aexon) {
        var newTowers: [Tower] = []
        aexon.createCores().forEach { (core: Core) in
            core.tower = core.createTower(self)
            newTowers.append(core.tower)
            core.aetherExe = self
            cores[core.key] = core
        }
        newTowers.forEach { $0.buildStream() }
    }
    
    public func inAFog(key: TokenKey) -> Bool { tower(key: key)?.fog != nil }
    
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
    
    func printTowers() { Tower.printTowers(towers) }
}

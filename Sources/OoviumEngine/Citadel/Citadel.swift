//
//  Citadel.swift
//  OoviumEngine
//
//  Created by Joe Charlier on 7/6/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import Acheron
import Aegean
import Foundation

public class Citadel {
    unowned let aether: Aether
    
    private var towers: [Tower] = []
    private var tokens: [TokenKey:TowerToken] = [:]
    private var cores: [TokenKey:Core] = [:]
    
    public private(set) var memory: UnsafeMutablePointer<Memory> = AEMemoryCreate(0)
    
    init(aether: Aether) {
        self.aether = aether
        build()
    }
    deinit { AEMemoryRelease(memory) }

// Computed ========================================================================================
    private func towerToken(key: TokenKey) -> TowerToken { tokens[key]! }
    public func tower(key: TokenKey) -> Tower? { tokens[key]?.tower }

// TokenKeys =======================================================================================
    public func chainCore(key: TokenKey) -> ChainCore { (cores[key] as! ChainCore) }
    public func tokenDisplay(key: TokenKey) -> String { cores[key]!.tokensDisplay }
    public func valueDisplay(key: TokenKey) -> String { cores[key]!.valueDisplay }
    public func naturalDisplay(key: TokenKey) -> String { cores[key]!.naturalDisplay }
    
// Private =========================================================================================
    private func reset() {
        tokens = [:]
        towers = []
        AEMemoryRelease(memory)
        memory = AEMemoryCreate(0)
    }
    private func build() {
        plugIn(aexons: aether.aexels)
        Citadel.evaluate(towers: Set(towers))
    }
    private func harvest(aexon: Aexon) -> [Tower] {
        var towers: [Tower] = []
        aexon.createCores().forEach { (core: Core) in
            let tower: Tower = Tower(citadel: self, core: core)
            core.tower = tower
            let towerTokens: [TowerToken] = core.createTowerTokens(self)
            towerTokens.forEach { (token: TowerToken) in
                if let variableToken: VariableToken = token as? VariableToken { tower.variableToken = variableToken }
                else if let mechlikeToken: MechlikeToken = token as? MechlikeToken { tower.mechlikeToken = mechlikeToken }
                token.tower = tower
            }
            self.towers.append(tower)
            towers.append(tower)
            cores[core.key] = core
        }
        return towers
    }
    private func buildMemory() {
        var vars: [String] = ["k"]
        vars += tokens.values.filter { $0.code == .va && $0.status != .deleted }.map { $0.tag }
        vars.sort(by: { $0.uppercased() < $1.uppercased() })

        let oldMemory: UnsafeMutablePointer<Memory> = memory
        memory = AEMemoryCreate(vars.count)
        vars.enumerated().forEach { AEMemorySetName(memory, UInt16($0), $1.toInt8()) }
        AEMemoryLoad(memory, oldMemory)
        AEMemoryRelease(oldMemory)
    }

    private func nukeUpstream(tower: Tower) {
        tower.upstream.forEach { $0.downstream.nuke(tower: tower) }
        tower.upstream.nukeAll()
    }

// Methods =========================================================================================
    // Listeners ===================================================================================
    public func notifyListeners() { Citadel.notifyListeners(towers: Set<Tower>(towers)) }
    
    // Manipulate ==================================================================================
    public func plugIn(aexons: [Aexon]) {
        let towers: [Tower] = aexons.flatMap({ harvest(aexon: $0) })
        cores.values.forEach { $0.citadel = self }
        towers.forEach { $0.buildStream() }
        buildMemory()
    }
    public func increment(key: TokenKey, dependenceOn: TokenKey) {
        let keyTower: Tower = tower(key: key)!
        let dependsOnTower: Tower = tower(key: dependenceOn)!
        keyTower.upstream.increment(tower: dependsOnTower)
        dependsOnTower.downstream.increment(tower: keyTower)
    }
    public func decrement(key: TokenKey, dependenceOn: TokenKey) {
        let keyTower: Tower = tower(key: key)!
        let dependsOnTower: Tower = tower(key: dependenceOn)!
        keyTower.upstream.decrement(tower: dependsOnTower)
        dependsOnTower.downstream.decrement(tower: keyTower)
    }
    
    public func nukeUpstream(key: TokenKey) { nukeUpstream(tower: tower(key: key)!) }
    public func nuke(key: TokenKey) {
        guard let tower: Tower = tower(key: key) else { return }
        nukeUpstream(tower: tower)
        towers.remove(object: tower)
        tokens[key] = nil
        cores[key] = nil
    }
    public func nuke(keys: [TokenKey]) { keys.forEach { nuke(key: $0) } }
    public func rekey(subs: [TokenKey:TokenKey?]) {
        var newTokens: [TokenKey:TowerToken] = [:]
        var newCores: [TokenKey:Core] = [:]
        subs.forEach { (tokenKey: TokenKey, value: TokenKey?) in
            if let newTokenKey: TokenKey = value {
                let token: TowerToken = tokens[tokenKey]!
                token.key = newTokenKey
                newTokens[newTokenKey] = token
                tokens[tokenKey] = nil
                newCores[newTokenKey] = cores[tokenKey]
                cores[tokenKey] = nil
                
            } else { nuke(key: tokenKey) }
        }
        tokens.merge(newTokens) { (a: TowerToken, b: TowerToken) in
            print("a: \(a)")
            print("b: \(b)")

            fatalError()
        }
            
        cores.merge(newCores) { (_,_) in fatalError() }
    }
    public func reevaluate() {
        reset()
        build()
    }

    // Query =======================================================================================
    public func anyToken(key: TokenKey) -> Token { tokens[key] ?? Token.token(key: key) ?? .zero }
    public func value(key: TokenKey) -> String? { (anyToken(key: key) as? VariableToken)?.value }
    public func inAFog(key: TokenKey) -> Bool { tower(key: key)?.fog != nil }
    public func canBeAdded(thisKey: TokenKey, to thatKey: TokenKey) -> Bool {
        guard let that: Tower = tower(key: thatKey),
              let this: Tower = tower(key: thisKey)
        else { return true }
        if that.downstream(contains: this) { return false }
        guard let thisFog: TokenKey = this.fog, let thatFog: TokenKey = that.fog else { return true }
        return thisFog == thatFog
    }
    public func nukable(keys: [TokenKey]) -> Bool {
        let towers: Set<Tower> = Set(keys.compactMap({ tower(key: $0) }))
        let downstream: Set<Tower> = Set(towers.flatMap({ $0.downstream.towersSet }))
        return downstream.isSubset(of: towers)
    }
    
    // Trigger =====================================================================================
    public func trigger(keys: [TokenKey]) {
        let towersArray: [Tower] = keys.map({ tower(key: $0)! })
        var towersSet: Set<Tower> = Set()
        towersArray.forEach { towersSet.formUnion($0.allDownstream()) }
        buildMemory()
        Citadel.evaluate(towers: towersSet)
    }
    public func trigger(key: TokenKey) { trigger(keys: [key]) }

    // Utility =====================================================================================
    public func paste(array: [[String:Any]], at v2: V2) -> [Aexel] {
        var substitutions: [TokenKey:TokenKey] = [:]
        var aexels: [Aexel] = []
        let tempAether: Aether = Aether()
        
        var minX: Double! = nil
        var maxX: Double! = nil
        var minY: Double! = nil
        var maxY: Double! = nil
        array.forEach { (attributes: [String:Any]) in
            let x: Double = attributes["x"] as! Double
            let y: Double = attributes["y"] as! Double
            if minX == nil || x < minX { minX = x }
            if maxX == nil || x > maxX { maxX = x }
            if minY == nil || y < minY { minY = y }
            if maxY == nil || y > maxY { maxY = y }
        }
        array.forEach { (attributes: [String:Any]) in
            var attributes = attributes
            var aexel: Aexel = Loom.domain(attributes: attributes, parent: tempAether) as! Aexel
            let fromKeys: [TokenKey] = aexel.tokenKeys.sorted(by: { $0.description < $1.description })
            attributes["no"] = aether.newNo(type: aexel.type)
            aexel = Loom.domain(attributes: attributes, parent: aether, replicate: true) as! Aexel
            aexel.x = v2.x - (maxX-minX)/2 + (aexel.x-minX)
            aexel.y = v2.y - (maxY-minY)/2 + (aexel.y-minY)
            let toKeys: [TokenKey] = aexel.tokenKeys.sorted(by: { $0.description < $1.description })
            aether.addAexel(aexel)
            for i in 0..<fromKeys.count { substitutions[fromKeys[i]] = toKeys[i] }
            aexels.append(aexel)
        }

        let chains: [Chain] = aexels.flatMap({ $0.chains })
        chains.forEach({
            $0.key = substitutions[$0.key!] ?? $0.key
            $0.tokenKeys = $0.tokenKeys.map({ substitutions[$0] ?? $0 })
        })
        
        // Handling Text Links
        let texts: [Text] = aexels.compactMap({ $0 as? Text })
        var textsLookup: [TokenKey:Text] = [:]
        texts.forEach({ textsLookup[$0.tokenKey] = $0 })
        texts.forEach { (text: Text) in
            text.edges.forEach({ (edge: Edge) in
                let oldKey: TokenKey = TokenKey(code: .tx, tag: "Tx\(edge.textNo)")
                if let newKey: TokenKey = substitutions[oldKey], let newText: Text = textsLookup[newKey] {
                    edge.textNo = newText.no
                }
            })
        }
        
        reset()
        build()

        return aexels
    }
    
    public func printTowers() { Citadel.printTowers(towers) }
    
    // =============================================================================================
    func towerToken(key: TokenKey, delegate: VariableTokenDelegate? = nil) -> TowerToken {
        if let tower: TowerToken = tokens[key] { return tower }
        let token: TowerToken
        switch key.code {
            case .va: token = VariableToken(tag: key.tag, delegate: delegate)
            case .ml: token = MechlikeToken(tag: key.tag, delegate: delegate)
            case .cl: token = ColumnToken(tag: key.tag, delegate: delegate)
            default: fatalError()
        }
        tokens[key] = token
        return token
    }
    
// Static ==========================================================================================
    public static func allDownstream(towers: Set<Tower>) -> Set<Tower> {
        var result: Set<Tower> = Set<Tower>()
        towers.forEach { result.formUnion($0.allDownstream()) }
        return result
    }
    public static func evaluate(towers: Set<Tower>) {
        towers.forEach { $0.core?.resetTask(tower: $0) }
        var progress: Bool
        repeat {
            progress = false
            towers.forEach { if $0.attemptToCalculate() { progress = true } }
        } while progress
        notifyListeners(towers: towers)
    }
    public static func trigger(towers: Set<Tower>) {
        var evaluate: Set<Tower> = Set(towers)
        towers.forEach({ evaluate.formUnion($0.allDownstream()) })
        Citadel.evaluate(towers: evaluate)
    }
    
    private static var listeners: [TokenKey:WeakListener] = [:]
    public static func startListening(to key: TokenKey, listener: TowerListener) { listeners[key] = WeakListener(listener) }
    static func cleanupListeners() { listeners = listeners.filter({ $1.value != nil }) }
    public static func nukeListeners() { listeners = [:] }
    public static func notifyListeners(towers: Set<Tower>) {
        cleanupListeners()
        towers.compactMap({ listeners[$0.variableToken.key]?.value }).forEach { $0.onTriggered() }
    }

    public static func printTowers(_ towers: WeakSet<Tower>) {
        print("[ Towers =================================== ]\n")
        for tower in towers { print("\(tower)") }
        print("[ ========================================== ]\n\n")
    }
    public static func printTowers(_ towers: Set<Tower>) {
        print("[ Towers =================================== ]\n")
        for tower in towers { print("\(tower)") }
        print("[ ========================================== ]\n\n")
    }
    static func printTowers(_ towers: [Tower]) {
        print("[ Towers =================================== ]\n")
        towers.forEach { print("\($0)") }
        print("[ ========================================== ]\n\n")
    }
}

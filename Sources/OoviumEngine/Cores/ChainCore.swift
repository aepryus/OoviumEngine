//
//  ChainCore.swift
//  OoviumEngine
//
//  Created by Joe Charlier on 7/10/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import Aegean
import Foundation

public class ChainCore: Core, CustomStringConvertible {
    let chain: Chain
    let _fog: TokenKey?
    weak var variableTokenDelegate: VariableTokenDelegate?
    
    public var tokens: [Token] = []

    init(chain: Chain, fog: TokenKey? = nil, variableTokenDelegate: VariableTokenDelegate? = nil) {
        self.chain = chain
        self._fog = fog
        self.variableTokenDelegate = variableTokenDelegate
    }
    
    override var fog: TokenKey? {
        if let _fog { return _fog }
        let upstreamTowers: [Tower] = tokens.compactMap({ aetherExe.tower(key: $0.key) })
        return upstreamTowers.first(where: { $0.fog != nil })?.fog
    }
    override var isFogFirewall: Bool { _fog != nil }
    
// Public ==========================================================================================
    public override var tokensDisplay: String { tokens.map({ $0.display }).joined() }
    public override var valueDisplay: String { tokens.count > 0 ? tower?.obje.display ?? "" : "" }
    public override var naturalDisplay: String { fatalError() }
    public func edit() {
        guard let tower else { return }
        Tower.notifyListeners(towers: [tower])
        AETaskRelease(tower.task)
        tower.task = AETaskCreateNull()
    }
    public func ok() {
        guard let tower else { return }
        tower.buildTask()
        tower.trigger()
    }
    
    public func replaceWith(tokens: String) {
        let keys: [TokenKey] = tokens.components(separatedBy: ";").map({ TokenKey($0) })
        chain.tokenKeys = keys
    }
    public func replaceWith(natural: String) {
        chain.tokenKeys = Chain.convert(natural: natural)
    }
    public func exchange(substitutions: [TokenKey:Token]) {
        var tokens: [Token] = []
        self.tokens.forEach({ (token: Token) in
            tokens.append(substitutions[token.key] ?? token)
        })
        self.tokens = tokens
    }

// Calculate =======================================================================================
    func loadTokens() {
        guard let aetherExe else { return }
        tokens = chain.tokenKeys.map({ (key: TokenKey) in aetherExe.token(key: key) })
    }
    public func calculate(vars: [String:Obje] = [:]) -> Obj? {
        let aether: Aether = Aether()
        let aetherExe: AetherExe = aether.compile()
        let memory: UnsafeMutablePointer<Memory> = AEMemoryCreate(vars.count)
        var m: mnimi = 0
        vars.keys.forEach {
            guard let obj: Obj = vars[$0]?.obj else { return }
            AEMemorySetName(memory, m, $0.toInt8())
            AEMemorySet(memory, m, obj)
            m += 1
            let token = aetherExe.variableToken(tag: $0)
            token.def = Def.def(obj: obj)
        }
        self.aetherExe = aetherExe
        
        if let lambda: UnsafeMutablePointer<Lambda> = Parser.compile(tokens: tokens, tokenKey: chain.key, memory: memory).0 {
            return AELambdaExecute(lambda, memory)
        } else { return nil }
    }

// Compiling =======================================================================================
    public func compile(name: String, tower: Tower) -> UnsafeMutablePointer<Lambda>? {
        let (lambda, lastMorphNo) = Parser.compile(tokens: tokens, tokenKey: chain.key, memory: tower.memory)
        if let lambda {
            if tower.variableToken.status == .invalid { tower.variableToken.status = .ok }
            if let lastMorphNo {
                let morph = Morph(rawValue: lastMorphNo)
                tower.variableToken.def = morph.def
            }
            else { tower.variableToken.def = RealDef.def }
            return lambda
        } else {
            if tower.variableToken.status == .ok { tower.variableToken.status = .invalid }
            return nil
        }
    }

// Core ===================================================================================
    override var key: TokenKey { chain.key! }
    
    override func createTower(_ aetherExe: AetherExe) -> Tower { aetherExe.createTower(key: key, core: self, variableTokenDelegate: variableTokenDelegate) }
    override func aetherExeCompleted(_ aetherExe: AetherExe) { loadTokens() }

    override func buildUpstream(tower: Tower) {
        if tower.core?.key == TokenKey(code: .va, tag: "Me1.result") {
            print("found it")
        }
        
        
        aetherExe.nukeUpstream(key: chain.key!)
        tokens.compactMap { $0 as? TowerToken }.forEach {
            $0.tower.attach(tower)
        }
    }
    override func renderDisplay(tower: Tower) -> String {
        if tower.variableToken.status == .deleted { fatalError() }
        if tower.variableToken.status == .invalid { return "INVALID" }
        if tower.variableToken.status == .blocked { return "BLOCKED" }
        
        if let label = tower.variableToken.alias { return label }
        return description
    }
    override func renderTask(tower: Tower) -> UnsafeMutablePointer<Task>? {
        let lambda: UnsafeMutablePointer<Lambda>? = compile(name: tower.name, tower: tower)
        let task: UnsafeMutablePointer<Task> = lambda != nil ? AETaskCreateLambda(lambda) : AETaskCreateNull()
        AETaskSetLabels(task, tower.variableToken.tag.toInt8(), "\(tower.variableToken.alias ?? tower.variableToken.tag) = \(tokensDisplay)".toInt8())
        return task
    }
    override func taskCompleted(tower: Tower, askedBy: Tower) -> Bool {
        AEMemoryLoaded(tower.memory, tower.index) != 0
    }
    override func taskBlocked(tower: Tower) -> Bool {
        tokens.compactMap({ $0 as? TowerToken }).contains { $0.status != .ok }
    }
    override func resetTask(tower: Tower) {
        loadTokens()
        AEMemoryUnfix(tower.memory, tower.index)
    }
    override func executeTask(tower: Tower) {
        AETaskExecute(tower.task, tower.memory)
        AEMemoryFix(tower.memory, tower.index)
        tower.variableToken.def = tower.obje.def
    }
    
// CustomStringConvertible =========================================================================
    private var shouldDisplayTokens: Bool { tower?.fog != nil || tower?.variableToken.status != .ok }
    public var description: String {
        guard tokens.count > 0 else { return "" }
        guard shouldDisplayTokens else { return tower?.obje.display ?? "" }
        return tokens.map({ $0.display }).joined()
    }
}

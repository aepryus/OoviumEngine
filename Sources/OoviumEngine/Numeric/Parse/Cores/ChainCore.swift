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
    
    public var tokens: [Token] = []

    init(chain: Chain, fog: TokenKey? = nil) {
        self.chain = chain
        self._fog = fog
    }
    
    override var fog: TokenKey? {
        if let _fog { return _fog }
        let upstreamTowers: [Tower] = tokens.compactMap({ aetherExe.tower(key: $0.key) })
        return upstreamTowers.first(where: { $0.fog != nil })?.fog
    }
    override var isFogFirewall: Bool { _fog != nil }
    
// Private =========================================================================================
//    private var currentParam: Int {
//        var param = [Int]()
//        
//        for token in tokens {
//            if token.code == .fn || token.code == .ml {
//                param.append(1)
//
//            } else if token.code == .sp {
//                if token.tag == "(" {
//                    param.append(1)
//
//                } else if token.tag == "," {
//                    param.append(param.removeLast()+1)
//
//                } else if token.tag == ")" {
//                    param.removeLast()
//                }
//            }
//        }
//        
//        return param.last ?? 0
//    }
//    private var noOfParams: Int {
//        var lefts: [Token] = []
//        for token in tokens {
//            if token is FunctionToken || token is MechlikeToken {
//                lefts.append(token)
//            } else if let token = token as? SeparatorToken {
//                if token.tag == "(" {
//                    lefts.append(token)
//                } else if token.tag == ")" {
//                    lefts.removeLast()
//                }
//            }
//        }
//        if let token = lefts.last as? FunctionToken { return token.params }
//        if let token = lefts.last as? MechlikeToken { return token.params }
//        return lefts.last != nil ? 1 : 0
//    }
//    private var lastIsOperator: Bool {
//        guard let last = tokens.last else {return true}
//        return last.code == .op
//    }
//    private var isNewSection: Bool {
//        guard let last = tokens.last else { return true }
//        return last.tag == "(" || last.tag == "[" || last.tag == "," || last.code == .fn || last.code == .ml || last.code == .op
//    }
//    private var isComplete: Bool {
//        guard noOfParams > 0 else { return false }
//        return currentParam == noOfParams
//    }
//    private func parenToken() -> Token? {
//        if lastIsOperator || isNewSection { return Token.leftParen }
//        else if isComplete { return Token.rightParen }
//        else if noOfParams > 0 { return Token.comma }
//        return nil
//    }
//    private func minusToken() -> Token {
//        return isNewSection ? Token.neg : Token.subtract
//    }
//    private func isWithinBracket() -> Bool {
//        var p: Int = 0
//        for token in tokens {
//            if token === Token.bra { p += 1 }
//            else if token === Token.ket { p -= 1 }
//        }
//        return p != 0
//    }
//    private func braketToken() -> Token? {
//        if lastIsOperator || isNewSection { return .bra }
//        else if isWithinBracket() { return .ket }
//        else { return nil }
//    }
    
// Public ==========================================================================================
    public var tokensDisplay: String { tokens.map({ $0.display }).joined() }
    public var valueDisplay: String { tokens.count > 0 ? tower?.obje.display ?? "" : "" }
    public var naturalDisplay: String { fatalError() }
    public func edit() {
        guard let tower else { return }
        tower.listener?.onTriggered()
        AETaskRelease(tower.task)
        tower.task = AETaskCreateNull()
    }
    public func ok() {
        guard let tower else { return }
        tower.buildTask()
        tower.trigger()
    }
    
//    public func attemptToPost(token: Token, at cursor: Int) -> Bool {
//        
//        if let this = tower, let towerToken = token as? TowerToken {
//            let that: Tower = towerToken.tower
//            if this.downstream(contains: that) { return false }
//            if let thisFog = this.fog, let thatFog = that.fog {
//                if thisFog != thatFog { return false }
//            }
//            that.attach(this)
//        }
//        
//        tokens.insert(token, at: cursor)
//        
//        return true
//    }
//    public func post(token: Token, at cursor: Int? = nil) {
//        let cursor: Int = cursor ?? tokens.count
//        _ = attemptToPost(token: token, at: cursor)
//    }
//    public func minusSign(at cursor: Int) {
//        post(token: minusToken(), at: cursor)
//    }
//    public func parenthesis(at cursor: Int) {
//        guard let parenToken = parenToken() else { return }
//        post(token: parenToken, at: cursor)
//    }
//    public func braket(at cursor: Int) {
//        guard let braketToken = braketToken() else { return }
//        post(token: braketToken, at: cursor)
//    }
//    private func removeToken(at cursor: Int) -> Token? {
//        let token: Token = tokens.remove(at: cursor)
//        if let this: Tower = tower, let that: Tower = (token as? TowerToken)?.tower, !tokens.contains(token) {
//            that.detach(this)
//        }
//        return token
//    }
//    public func backspace(at cursor: Int) -> Token? {             // delete left
//        guard cursor > 0 else { return nil }
//        return removeToken(at: cursor-1)
//    }
//    public func delete(at cursor: Int) -> Token? {                // delete right
//        guard cursor < tokens.count else { return nil }
//        return removeToken(at: cursor)
//    }
    public func isInString(at cursor: Int) -> Bool {
        var q: Int = 0
        for (i, token) in tokens.enumerated() {
            if i == cursor { break }
            if token == Token.quote {q += 1}
        }
        return q % 2 == 1
    }
    public var unmatchedQuote: Bool {
        var q: Int = 0
        for token in tokens {
            if token == Token.quote {q += 1}
        }
        return q % 2 == 1
    }
    public func contains(token: Token) -> Bool {
        for t in tokens {
            if t == token {return true}
        }
        return false
    }
    public func clear() {
        self.tokens.removeAll()
    }
    public func replaceWith(tokens: String) {
        let keys: [TokenKey] = tokens.components(separatedBy: ";").map({ TokenKey($0) })
        chain.tokenKeys = keys
//            buildTokens()
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
    
    override func aetherExeCompleted(_ aetherExe: AetherExe) {
        tokens = chain.tokenKeys.map({ (key: TokenKey) in aetherExe.token(key: key) })
    }

    override func buildUpstream(tower: Tower) { tokens.compactMap { $0 as? TowerToken }.forEach { $0.tower.attach(tower) } }
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
        AEMemoryUnfix(tower.memory, tower.index)
    }
    override func executeTask(tower: Tower) {
        AETaskExecute(tower.task, tower.memory)
        AEMemoryFix(tower.memory, tower.index)
        tower.variableToken.def = tower.obje.def
    }
    
// CustomStringConvertible =========================================================================
    private var shouldDisplayTokens: Bool { /*editing ||*/ tower?.fog != nil || tower?.variableToken.status != .ok /*|| alwaysShow*/ }
    public var description: String {
        guard tokens.count > 0 else { return "" }
        guard shouldDisplayTokens else { return tower?.obje.display ?? "" }
        return tokens.map({ $0.display }).joined()
    }

}

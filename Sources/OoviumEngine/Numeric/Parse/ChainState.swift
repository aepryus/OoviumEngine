//
//  ChainState.swift
//  OoviumEngine
//
//  Created by Joe Charlier on 7/10/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import Aegean
import Foundation

class ChainState: TowerDelegate, CustomStringConvertible {
    let chain: Chain
    
    var tokens: [Token] = []
    var tower: Tower?

    init(chain: Chain) { self.chain = chain }
    
// Computed ========================================================================================
    var key: ChainKey? { chain.key }
    
// Methods =========================================================================================
    func buildTokens(aetherState: AetherState?) {
        tokens = chain.tokenKeys.map({ (key: String) in
            aetherState?.token(key: TokenKey(key)) ?? Token.token(key: TokenKey(key)) ?? .zero
        })
        
        print("keys: [\(chain.tokenKeys.count)], tokens: [\(tokens.count)]")
    }
    
// Private =========================================================================================
    private var currentParam: Int {
        var param = [Int]()
        
        for token in tokens {
            if token.code == .fn || token.code == .ml {
                param.append(1)

            } else if token.code == .sp {
                if token.tag == "(" {
                    param.append(1)

                } else if token.tag == "," {
                    param.append(param.removeLast()+1)

                } else if token.tag == ")" {
                    param.removeLast()
                }
            }
        }
        
        return param.last ?? 0
    }
    private var noOfParams: Int {
        var lefts: [Token] = []
        for token in tokens {
            if token is FunctionToken || token is MechlikeToken {
                lefts.append(token)
            } else if let token = token as? SeparatorToken {
                if token.tag == "(" {
                    lefts.append(token)
                } else if token.tag == ")" {
                    lefts.removeLast()
                }
            }
        }
        if let token = lefts.last as? FunctionToken { return token.params }
        if let token = lefts.last as? MechlikeToken { return token.params }
        return lefts.last != nil ? 1 : 0
    }
    private var lastIsOperator: Bool {
        guard let last = tokens.last else {return true}
        return last.code == .op
    }
    private var isNewSection: Bool {
        guard let last = tokens.last else { return true }
        return last.tag == "(" || last.tag == "[" || last.tag == "," || last.code == .fn || last.code == .ml || last.code == .op
    }
    private var isComplete: Bool {
        guard noOfParams > 0 else { return false }
        return currentParam == noOfParams
    }
    private func parenToken() -> Token? {
        if lastIsOperator || isNewSection { return Token.leftParen }
        else if isComplete { return Token.rightParen }
        else if noOfParams > 0 { return Token.comma }
        return nil
    }
    private func minusToken() -> Token {
        return isNewSection ? Token.neg : Token.subtract
    }
    private func isWithinBracket() -> Bool {
        var p: Int = 0
        for token in tokens {
            if token === Token.bra { p += 1 }
            else if token === Token.ket { p -= 1 }
        }
        return p != 0
    }
    private func braketToken() -> Token? {
        if lastIsOperator || isNewSection {
            return .bra
        } else if isWithinBracket() {
            return .ket
        } else {
            return nil
        }
    }
    
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
    
    public func attemptToPost(token: Token, at cursor: Int) -> Bool {
        
        if let this = tower, let towerToken = token as? TowerToken {
            let that: Tower = towerToken.tower
            if this.downstream(contains: that) { return false }
            if let thisWeb = this.web ?? this.tailForWeb, let thatWeb = that.web {
                if thisWeb !== thatWeb { return false }
            }
            that.attach(this)
        }
        
        tokens.insert(token, at: cursor)
        
        return true
    }
    public func post(token: Token, at cursor: Int? = nil) {
        let cursor: Int = cursor ?? tokens.count
        _ = attemptToPost(token: token, at: cursor)
    }
    public func minusSign(at cursor: Int) {
        post(token: minusToken(), at: cursor)
    }
    public func parenthesis(at cursor: Int) {
        guard let parenToken = parenToken() else { return }
        post(token: parenToken, at: cursor)
    }
    public func braket(at cursor: Int) {
        guard let braketToken = braketToken() else { return }
        post(token: braketToken, at: cursor)
    }
    private func removeToken(at cursor: Int) -> Token? {
        let token: Token = tokens.remove(at: cursor)
        if let this: Tower = tower, let that: Tower = (token as? TowerToken)?.tower, !tokens.contains(token) {
            that.detach(this)
        }
        return token
    }
    public func backspace(at cursor: Int) -> Token? {             // delete left
        guard cursor > 0 else { return nil }
        return removeToken(at: cursor-1)
    }
    public func delete(at cursor: Int) -> Token? {                // delete right
        guard cursor < tokens.count else { return nil }
        return removeToken(at: cursor)
    }
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
        let keys = tokens.components(separatedBy: ";")
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
    public func calculate() -> Obj? {
        let memory: UnsafeMutablePointer<Memory> = AEMemoryCreate(0)
        buildTokens(aetherState: nil)
        if let lambda: UnsafeMutablePointer<Lambda> = Parser.compile(chain: chain, memory: memory).0 {
            return AELambdaExecute(lambda, memory)
        } else { return nil }
    }

// Compiling =======================================================================================
    
    public func compile(name: String, tower: Tower) -> UnsafeMutablePointer<Lambda>? {
        let (lambda, lastMorphNo) = Parser.compile(chain: self.chain, memory: tower.memory)
        if let lambda {
            if tower.variableToken.status == .invalid { tower.variableToken.status = .ok }
            if let lastMorphNo, let morph = Morph(rawValue: lastMorphNo) { tower.variableToken.def = morph.def }
            else { tower.variableToken.def = RealDef.def }
            return lambda
        } else {
            if tower.variableToken.status == .ok { tower.variableToken.status = .invalid }
            return nil
        }
    }

// TowerDelegate ===================================================================================
    func buildUpstream(tower: Tower) {
        tokens.compactMap { $0 as? TowerToken }.forEach {
            let upstream: Tower = $0.tower
            upstream.attach(tower)
        }
    }
    func renderDisplay(tower: Tower) -> String {
        if tower.variableToken.status == .deleted { fatalError() }
        if tower.variableToken.status == .invalid { return "INVALID" }
        if tower.variableToken.status == .blocked { return "BLOCKED" }
        
        if let label = tower.variableToken.alias { return label }
        return description
    }
    func renderTask(tower: Tower) -> UnsafeMutablePointer<Task>? {
        let lambda: UnsafeMutablePointer<Lambda>? = compile(name: tower.name, tower: tower)
        let task: UnsafeMutablePointer<Task> = lambda != nil ? AETaskCreateLambda(lambda) : AETaskCreateNull()
        AETaskSetLabels(task, tower.variableToken.tag.toInt8(), "\(tower.variableToken.alias ?? tower.variableToken.tag) = \(tokensDisplay)".toInt8())
        return task
    }
    func taskCompleted(tower: Tower, askedBy: Tower) -> Bool {
        AEMemoryLoaded(tower.memory, tower.index) != 0
    }
    func taskBlocked(tower: Tower) -> Bool {
        tokens.compactMap({ $0 as? TowerToken }).contains { $0.status != .ok }
    }
    func resetTask(tower: Tower) {
        AEMemoryUnfix(tower.memory, tower.index)
    }
    func executeTask(tower: Tower) {
        AETaskExecute(tower.task, tower.memory)
        AEMemoryFix(tower.memory, tower.index)
        tower.variableToken.def = tower.obje.def
    }
    
// CustomStringConvertible =========================================================================
    private var shouldDisplayTokens: Bool { /*editing ||*/ tower?.web != nil || tower?.variableToken.status != .ok /*|| alwaysShow*/ }
    public var description: String {
        guard tokens.count > 0 else { return "" }
        guard shouldDisplayTokens else { return tower?.obje.display ?? "" }
        
        var sb = String()
        tokens.forEach { sb.append("\($0.display)") }
        return sb
    }

}

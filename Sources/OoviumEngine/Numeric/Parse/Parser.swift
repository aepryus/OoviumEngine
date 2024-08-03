//
//  Parser.swift
//  OoviumEngine
//
//  Created by Joe Charlier on 7/11/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import Aegean
import Foundation

fileprivate class Ops {
    unowned private let parser: Parser
    
    weak private var pOp: OperatorToken?
    weak private var mOp: OperatorToken?
    weak private var aOp: OperatorToken?
    weak private var cOp: OperatorToken?
    weak private var gOp: OperatorToken?
    
    init(_ parser: Parser) { self.parser = parser }
    
    private func doPOP(_ token: OperatorToken?) throws {
        if let pOp = pOp { try parser.apply(token: pOp) }
        pOp = token
    }
    private func doMOP(_ token: OperatorToken?) throws {
        if let mOp = mOp { try parser.apply(token: mOp) }
        mOp = token
    }
    private func doAOP(_ token: OperatorToken?) throws {
        if let aOp = aOp { try parser.apply(token: aOp) }
        aOp = token
    }
    private func doCOP(_ token: OperatorToken?) throws {
        if let cOp = cOp { try parser.apply(token: cOp) }
        cOp = token
    }
    private func doGOP(_ token: OperatorToken?) throws {
        if let gOp = gOp { try parser.apply(token: gOp) }
        gOp = token
    }
    
    func pOp(_ token: OperatorToken) throws {
        try doPOP(token)
    }
    func mOp(_ token: OperatorToken) throws {
        try doPOP(nil)
        try doMOP(token)
    }
    func aOp(_ token: OperatorToken) throws {
        try doPOP(nil)
        try doMOP(nil)
        try doAOP(token)
    }
    func cOp(_ token: OperatorToken) throws {
        try doPOP(nil)
        try doMOP(nil)
        try doAOP(nil)
        try doCOP(token)
    }
    func gOp(_ token: OperatorToken) throws {
        try doPOP(nil)
        try doMOP(nil)
        try doAOP(nil)
        try doCOP(nil)
        try doGOP(token)
    }
    func end() throws {
        try doPOP(nil)
        try doMOP(nil)
        try doAOP(nil)
        try doCOP(nil)
        try doGOP(nil)
    }
}

enum ParseError: Error { case general }

class Parser {
    let tokens: [Token]
    
    var morphs: [UInt32] = []
    var variables: [String] = []
    var constants: [Obje] = []
    var stack: [String] = [String](repeating: "", count: 10)
    var sp: Int = 0
    
    init(tokens: [Token]) { self.tokens = tokens }

    // Stack
    func push(_ key: String) {
        stack[sp] = key;
        sp += 1
        if sp == 10 {sp = 0}
    }
    func pop() -> String {
        sp -= 1
        if sp == -1 {sp = 9}
        return stack[sp]
    }
    func peek() -> String { stack[sp-1] }

    private func addMorph(_ morph: UInt32) {
        morphs.append(morph)
        let morph = Morph(rawValue: morph)
        push(morph.def.key)
    }
    private func addConstant(_ obje: Obje) throws {
        constants.append(obje)
        push(obje.def.key)
        try apply(tag: "cns", params: 1)
    }

    fileprivate func apply(tag: String, params: Int) throws {
        var key = "\(tag);"
        var defKeys: [String] = []
        for _ in 0..<params { defKeys.append(pop()) }
        for i in 0..<params { key += "\(defKeys[params-1-i]);" }
        try addMorph(Math.morph(key: key))
    }
    fileprivate func apply(token: Paramsable) throws {
        try apply(tag: token.tag, params: token.params)
    }
    fileprivate func apply(token: OperatorToken) throws {
        try apply(tag: token.tag, params: 2)
    }
    fileprivate func apply(token: UnaryToken) throws {
        try apply(tag: token.tag, params: 1)
    }

    private func parseOperator(i:Int, ops:Ops) throws {
        if let token: OperatorToken = tokens[i] as? OperatorToken {
            switch token.level {
                case .add:      try ops.aOp(token)
                case .multiply: try ops.mOp(token)
                case .power:    try ops.pOp(token)
                case .compare:  try ops.cOp(token)
                case .gate:     try ops.gOp(token)
            }
        }
        else if tokens[i].code == .sp { try ops.end() }
        else { throw ParseError.general }
    }
    
    private func findEnd(_ n: Int) throws -> Int {
        var i: Int = n
        var p: Int = 1
        
        while p != 0 && i<tokens.count {
            let token = tokens[i]
            if tokens[i] === Token.leftParen || tokens[i].code == .fn || tokens[i].code == .ml { p += 1 }
            else if token === Token.rightParen { p -= 1 }
            i += 1
        }
        if p != 0 { throw ParseError.general }
        return i-1
    }
    private func parseNumber(i: Int) -> String {
        var sb = String()
        for i in i..<tokens.count {
            let token = tokens[i]
            if token.code != .dg { break }
            sb.append(token.tag)
        }
        return sb;
    }
    private func parseChain(i: Int) throws -> [Token] {
        var i: Int = i
        var p: Int = 1
        var result: [Token] = []
        while p > 0 && i < tokens.count-1 {
            result.append(tokens[i])
            i += 1
            if tokens[i] == .bra { p += 1 }
            else if tokens[i] == .ket { p -= 1}
        }
        if p > 0 { throw ParseError.general }
        return result
    }
    private func parseString(i: Int) throws -> String  {
        var sb = String()
        var i: Int = i+1
        while i < tokens.count {
            if tokens[i] == Token.quote {break}
            sb += tokens[i].tag
            i += 1
            if i == tokens.count {throw ParseError.general}
        }
        return sb
    }
    private func parseOperand(i: Int) throws -> Int {
        guard tokens.count > i else { throw ParseError.general }

        var i: Int = i
        var token: Token = tokens[i]

        // Fix for imported unary Tokens ========
//        if tokens[i] === Token.subtract {
//            tokens[i] = Token.neg
//            token = Token.neg
//        }
        // ======================================

        var unary: UnaryToken?
        if let ut = token as? UnaryToken {
            unary = ut
            i += 1
            if (i == tokens.count) { throw ParseError.general }
            token = tokens[i]
        }
        
        if token.code == .dg {
            let n: String = parseNumber(i:i)
            let x: Double = Double(n) ?? Double.nan
            try addConstant(Obje(AEObjReal(x)))
            if let unary = unary { try apply(token: unary) }
            return n.lengthOfBytes(using: .ascii) + (unary != nil ? 1 : 0)
        } else if token == .leftParen {
            i += 1
            let e = try findEnd(i)
            try parseTokens(start: i, stop: e)
            if let unary = unary { try apply(token: unary) }
            return 2 + e - i + (unary != nil ? 1 : 0)
        } else if let token = token as? FunctionToken {
            i += 1
            let e = try findEnd(i)
            try parseTokens(start: i, stop: e)
            try apply(token: token)
            if let unary = unary { try apply(token: unary) }
            return 2 + e - i + (unary != nil ? 1 : 0)
        } else if let token = token as? MechlikeToken {
            i += 1
            let e = try findEnd(i)
            try parseTokens(start: i, stop: e)
            variables.append(token.tag)
            addMorph(MorphRecipe.rawValue)
            if let unary = unary { try apply(token: unary) }
            return 2 + e - i + (unary != nil ? 1 : 0)
        } else if token == .bra {
            i += 1
            let tokens: [Token] = try parseChain(i: i)
//            let chain: Chain = Chain(tokens: tokens)
//            chain.tower = tower
            // The name sent to compile is used to set the lambda index vi, but since vi won't be used in this case I'm sending 'k' in just to ensure the name is found.
            // This needs to be cleaned up. 5/11/20
//            try addConstant(Obje(AEObjLambda(chain.compile(name: "k", tower: tower))))
            return tokens.count + 2
        } else if let token = token as? VariableToken {
            let name = token.tag
            let type = "var;\(token.def?.key ?? "num");"
            variables.append(name)
            try addMorph(Math.morph(key: type))
            if let unary = unary { try apply(token: unary) }
            return 1 + (unary != nil ? 1 : 0)
            
        } else if let token = token as? KToken {
            let name = token.tag
            let type = "var;num;"
            variables.append(name)
            try addMorph(Math.morph(key: type))
            if let unary = unary { try apply(token: unary) }
            return 1 + (unary != nil ? 1 : 0)
            
        } else if token.code == .cn {

            if token == Token.i { try addConstant(Obje.i) }
            else if token == Token.e { try addConstant(Obje.e) }
            else if token == Token.pi { try addConstant(Obje.pi) }
            else if token == Token.yes { try addConstant(Obje.yes) }
            else if token == Token.no { try addConstant(Obje.no) }
            else if token == Token.chill { try addConstant(Obje.chill) }
            else if token == Token.eat { try addConstant(Obje.eat) }
            else if token == Token.flirt { try addConstant(Obje.flirt) }
            else if token == Token.fight { try addConstant(Obje.fight) }
            else if token == Token.flee { try addConstant(Obje.flee) }
            else if token == Token.wander { try addConstant(Obje.wander) }

            if let unary = unary { try apply(token: unary) }
            return 1 + (unary != nil ? 1 : 0)

        } else if token == Token.quote {
            let text: String = try parseString(i: i)
            try addConstant(Obje(AEObjString(text.toInt8())))
            return text.count+2
        }
        
        throw ParseError.general
    }
    private func parseTokens(start:Int, stop:Int) throws {
        if tokens.count == 0 || start == stop { return }
        let ops: Ops = Ops(self)
        var i: Int = start
        i += try parseOperand(i:i)
        while i < stop {
            try parseOperator(i:i, ops:ops)
            i += 1
            i += try parseOperand(i:i)
        }
        try ops.end()
    }

    private func compile(tokenKey: TokenKey?, memory: UnsafeMutablePointer<Memory>) -> (UnsafeMutablePointer<Lambda>?, UInt32?) {
        do { try parseTokens(start:0, stop:tokens.count) }
        catch { return (nil, nil) }

        let vi: mnimi
        if let key: TokenKey = tokenKey { vi = AEMemoryIndexForName(memory, key.description.toInt8()) }
        else { vi = 0 }
        
        let vn: Int = variables.count
        let v: UnsafeMutablePointer<mnimi> = UnsafeMutablePointer<mnimi>.allocate(capacity: vn)
        defer { v.deallocate() }
        for i in 0..<vn { v[i] = AEMemoryIndexForName(memory, variables[i].toInt8()) }
        
        let cn: Int = constants.count
        let c: UnsafeMutablePointer<Obj> = UnsafeMutablePointer<Obj>.allocate(capacity: cn)
        defer { c.deallocate() }
        for i in 0..<cn { c[i] = AEObjMirror(constants[i].obj) }
        
        let mn: Int = morphs.count
        let m: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: mn)
        defer { m.deallocate() }
        for i in 0..<mn { m[i] = UInt8(morphs[i]) }

        return (AELambdaCreate(vi, c, UInt8(cn), v, UInt8(vn), m, UInt8(mn), Token.display(tokens: tokens).toInt8()), morphs.last)
    }
    
    static func compile(tokenKey: TokenKey?, tokens: [Token], memory: UnsafeMutablePointer<Memory>) -> (UnsafeMutablePointer<Lambda>?, UInt32?) { Parser(tokens: tokens).compile(tokenKey: tokenKey, memory: memory) }
}

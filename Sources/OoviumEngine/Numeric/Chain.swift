//
//  Chain.swift
//  Oovium
//
//  Created by Joe Charlier on 10/1/16.
//  Copyright © 2016 Aepryus Software. All rights reserved.
//

/* =================================================================================================
Chain is the object representing a single mathematical statement made up of an array of tokens.  It
contains the ability to parse those tokens into mathematical meaning as well as handle the posting
of new tokens or removal of existing tokens to the chain.

The chain can be used standalone and calculate one off results or can be used as a Tower manager.  As
a tower manager it is resposible for maintaining it's tower's upstream connections.  It is also
responsible for compiling itself and uploading the LambdaTask to the tower.
================================================================================================= */

import Acheron
import Foundation

public class Chain: NSObject, Packable {
    public var key: TokenKey?
    public var tokenKeys: [TokenKey]
    
// Inits ===========================================================================================
    public init(key: TokenKey? = nil) {
        self.key = key
        tokenKeys = []
    }
	public init(natural: String) {
        self.key = nil
        self.tokenKeys = Chain.convert(natural: natural)
	}
    
// Packable ========================================================================================
    public required init(_ chainString: String) {
        var chainString = chainString
        if let index = chainString.loc(of: "::") {
            key = TokenKey(chainString[..<index])
            chainString.removeFirst(index+2)
        } else { key = nil }
        if !chainString.isEmpty { tokenKeys = chainString.components(separatedBy: ";").map({ TokenKey($0) }) }
        else { tokenKeys = [] }
	}
	public func pack() -> String {
        var chainString: String = ""
        if let key {
            if key.code == .va { chainString += "\(key.tag)::" }
            else { chainString += "\(key)::" }
        }
        chainString += tokenKeys.map({ $0.description }).joined(separator: ";")
        return chainString
	}
    
// Computed ========================================================================================
    public var isEmpty: Bool { tokenKeys.isEmpty }
    
// Private =========================================================================================
    private var currentParam: Int {
        var params: [Int] = []
        tokenKeys.forEach { (key: TokenKey) in
            if key.code == .fn || key.code == .ml { params.append(1) }
            else if key.code == .sp {
                if key.tag == "(" { params.append(1) }
                else if key.tag == "," { params[params.count - 1] += 1 }
                else if key.tag == ")" { params.removeLast() }
            }
        }
        return params.last ?? 0
    }
    private var noOfParams: Int {
        var lefts: [TokenKey] = []
        tokenKeys.forEach { (key: TokenKey) in
            if key.code == .fn || key.code == .ml { lefts.append(key) }
            else if key.code == .sp {
                if key.tag == "(" { lefts.append(key) }
                else if key.tag == ")" { lefts.removeLast() }
            }
        }
        guard let last: TokenKey = lefts.last else { return 0 }
        if last.code == .fn { return (Token.token(key: last) as! FunctionToken).params }
        if last.code == .ml { return (Token.token(key: last) as! MechlikeToken).params }
        return 1
    }
    private var lastIsOperator: Bool {
        guard let last: TokenKey = tokenKeys.last else { return true }
        return last.code == .op
    }
    private func isNewSection(at cursor: Int) -> Bool {
        guard tokenKeys.indices ~= (cursor - 1) else { return true }
        let lastKey: TokenKey = tokenKeys[cursor-1]
        return lastKey.tag == "(" || lastKey.tag == "[" || lastKey.tag == "," || lastKey.code == .fn || lastKey.code == .ml || lastKey.code == .op
    }
    private var isComplete: Bool {
        guard noOfParams > 0 else { return false }
        return currentParam == noOfParams
    }
    private func parenKey(at cursor: Int) -> TokenKey? {
        if lastIsOperator || isNewSection(at: cursor) { return Token.leftParen.key }
        else if isComplete { return Token.rightParen.key }
        else if noOfParams > 0 { return Token.comma.key }
        return nil
    }
    private func minusKey(at cursor: Int) -> TokenKey { isNewSection(at: cursor) ? Token.neg.key : Token.subtract.key }
    private func isWithinBracket() -> Bool {
        var p: Int = 0
        tokenKeys.forEach { (key: TokenKey) in
            if key == Token.bra.key { p += 1 }
            else if key == Token.ket.key { p -= 1 }
        }
        return p != 0
    }
    private func braketKey(at cursor: Int) -> TokenKey? {
        if lastIsOperator || isNewSection(at: cursor) { return Token.bra.key }
        else if isWithinBracket() { return Token.ket.key }
        else { return nil }
    }
    
// Methods =========================================================================================
    public func post(key: TokenKey) { tokenKeys.append(key) }
    public func post(key: TokenKey, at cursor: Int? = nil) {
        let cursor: Int = cursor ?? tokenKeys.count
        tokenKeys.insert(key, at: cursor)
    }
    public func removeKey() { tokenKeys.removeLast() }
    
    public func minusSign(at cursor: Int) { post(key: minusKey(at: cursor), at: cursor) }
    public func parenthesis(at cursor: Int) {
        guard let parenKey = parenKey(at: cursor) else { return }
        post(key: parenKey, at: cursor)
    }
    public func braket(at cursor: Int) {
        guard let braketKey = braketKey(at: cursor) else { return }
        post(key: braketKey, at: cursor)
    }
    private func removeKey(at cursor: Int) -> TokenKey? {
        tokenKeys.remove(at: cursor)
    }
    public func backspace(at cursor: Int) -> TokenKey? {             // delete left
        guard cursor > 0 else { return nil }
        return removeKey(at: cursor-1)
    }
    public func delete(at cursor: Int) -> TokenKey? {                // delete right
        guard cursor < tokenKeys.count else { return nil }
        return removeKey(at: cursor)
    }
    
    public func isInString(at cursor: Int) -> Bool {
        var q: Int = 0
        for (i, key) in tokenKeys.enumerated() {
            if i == cursor { break }
            if key == Token.quote.key { q += 1 }
        }
        return q % 2 == 1
    }
    public var unmatchedQuote: Bool {
        var q: Int = 0
        for key in tokenKeys {
            if key == Token.quote.key { q += 1 }
        }
        return q % 2 == 1
    }
    public func contains(key: TokenKey) -> Bool {
        for k in tokenKeys {
            if k == key { return true }
        }
        return false
    }
    public func clear() { tokenKeys.removeAll() }
    
    public func compile() -> ChainCore { ChainCore(chain: self) }

// ChainCore ======================================================================================
    public func replaceWith(natural: String) { tokenKeys = Chain.convert(natural: natural) }
    
// Static ==========================================================================================
    static func convert(natural: String) -> [TokenKey] {
        var isStart: Bool = true
        var keys: [TokenKey] = []
        var i: Int = 0
        while i < natural.count {
            var tag: String = Token.aliases["\(natural[i])"] ?? "\(natural[i])"
            let code: TokenCode
            if natural[i].isWholeNumber || ["."].contains(natural[i]) { code = .dg }
            else if natural[i] == "!" { code = .un }
            else if natural[i] == "-" && isStart { code = .un }
            else if ["+", "-", "*", "/", "^"].contains(natural[i]) { code = .op }
            else if ["(", ",", ")"].contains(natural[i]) { code = .sp }
            else if ["e", "i", "π"].contains(natural[i]) { code = .cn }
            else if natural[i] == "\"" {
                keys.append(TokenKey(code: .sp, tag: "\""))
                i += 1
                let end: Int = natural.loc(of: "\"", after: i)!
                while i < end {
                    keys.append(TokenKey(code: .ch, tag: "\(natural[i])"))
                    i += 1
                }
                code = .sp
                tag = "\""
            } else {
                let start = i
                while i < natural.count && (natural[i].isLetter || natural[i].isNumber || natural[i] == "_") { i += 1 }
                tag = natural[start...(i-1)]
                if i < natural.count && natural[i] == "(" { code = .fn }
                else {
                    code = .va
                    i -= 1
                }
            }
            keys.append(TokenKey(code: code, tag: tag))
            isStart = (code == .fn || code == .ml || code == .op || ["(", "[", ","].contains(natural[i]))
            i += 1
        }
        
        return keys
    }
}

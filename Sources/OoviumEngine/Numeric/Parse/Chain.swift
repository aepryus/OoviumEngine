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

import Aegean
import Acheron
import Foundation

public struct ChainKey {
    let string: String
    
    init(_ string: String) { self.string = string }
    
    var display: String { return string }

// Hashable ========================================================================================
    public static func == (left: ChainKey, right: ChainKey) -> Bool { left.string == right.string }
    public func hash(into hasher: inout Hasher) { hasher.combine(string) }
}

public final class Chain: NSObject, Packable {
    let key: ChainKey?
    var tokenKeys: [String]
    
    private var state: ChainState!

// Inits ===========================================================================================
    public init(key: ChainKey? = nil) {
        self.key = key
        tokenKeys = []
    }
	public init(natural: String) {
        self.key = nil
        self.tokenKeys = Chain.convert(natural: natural)
	}
    
// Packable ========================================================================================
	public init(_ chainString: String) {
        var chainString = chainString
        if let index = chainString.loc(of: "::") {
            key = ChainKey(chainString[..<index])
            chainString.removeFirst(index+2)
        } else { key = nil }
        tokenKeys = chainString.components(separatedBy: ";")
	}
	public func pack() -> String {
        var chainString: String = ""
        if let key { chainString += "\(key)::" }
        chainString += state.tokens.map({ $0.key.display }).joined(separator: ";")
        return chainString
	}
    
// Methods =========================================================================================
    func load(state: ChainState) { self.state = state }
    func load(tokens: [Token]) { state.tokens = tokens }
    
// ChainState ======================================================================================
    public var tokens: [Token] { state.tokens }
    public var tower: Tower { state.tower! }
    
    public var tokensDisplay: String { state.tokensDisplay }
    public var valueDisplay: String { state.valueDisplay }
    public var naturalDisplay: String { state.naturalDisplay }
    public func edit() { state.edit() }
    public func ok() { state.ok() }

    public func attemptToPost(token: Token, at cursor: Int) -> Bool { state.attemptToPost(token: token, at: cursor) }
    public func post(token: Token, at cursor: Int? = nil) { state.post(token: token, at: cursor) }
    public func minusSign(at cursor: Int) { state.minusSign(at: cursor) }
    public func parenthesis(at cursor: Int) { state.parenthesis(at: cursor) }
    public func braket(at cursor: Int) { state.braket(at: cursor) }
    public func backspace(at cursor: Int) -> Token? { state.backspace(at: cursor) }
    public func delete(at cursor: Int) -> Token? { state.delete(at: cursor) }
    public func isInString(at cursor: Int) -> Bool { state.isInString(at: cursor) }
    public var unmatchedQuote: Bool { state.unmatchedQuote }
//    public func contains(token: Token) -> Bool { state.contains(token: token) }
    public func clear() { state.clear() }
    public func replaceWith(tokens: String) { state.replaceWith(tokens: tokens) }
    public func replaceWith(natural: String) { state.replaceWith(natural: natural) }
//    public func exchange(substitutions: [String:Token]) { state.exchange(substitutions: substitutions) }
    public func calculate() -> Obj? { state.calculate() }
    
// Static ==========================================================================================
    static func convert(natural: String) -> [String] {
        var isStart: Bool = true
        var keys: [String] = []
        var i: Int = 0
        while i < natural.count {
            var tag: String = Token.aliases["\(natural[i])"] ?? "\(natural[i])"
            let code: TokenCode
            if natural[i].isWholeNumber { code = .dg }
            else if natural[i] == "!" { code = .un }
            else if natural[i] == "-" && isStart { code = .un }
            else if ["+", "-", "*", "/", "^"].contains(natural[i]) { code = .op }
            else if ["(", ",", ")"].contains(natural[i]) { code = .sp }
            else if ["e", "i", "π"].contains(natural[i]) { code = .cn }
            else if natural[i] == "\"" {
                keys.append("\(TokenCode.sp):\"")
                i += 1
                let end: Int = natural.loc(of: "\"", after: i)!
                while i < end {
                    keys.append("\(TokenCode.ch):\(natural[i])")
                    i += 1
                }
                code = .sp
                tag = "\""
            } else {
                code = .fn
                if let left = natural.loc(of: "(", after: i) {
                    let end = left - 1
                    tag = natural[i...end]
                    i += tag.count
                } else {
                    return []
                }
            }
            keys.append("\(code):\(tag)")
            isStart = (code == .fn || code == .ml || ["(", "[", ","].contains(natural[i]))
            i += 1
        }
        return keys
    }
}

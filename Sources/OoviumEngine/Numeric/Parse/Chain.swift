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

public final class Chain: NSObject, Packable {
    public let key: TokenKey?
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
	public init(_ chainString: String) {
        var chainString = chainString
        if let index = chainString.loc(of: "::") {
            key = TokenKey(chainString[..<index])
            chainString.removeFirst(index+2)
        } else { key = nil }
        tokenKeys = chainString.components(separatedBy: ";").map({ TokenKey($0) })
	}
	public func pack() -> String {
        var chainString: String = ""
        if let key { chainString += "\(key)::" }
        chainString += tokenKeys.map({ $0.description }).joined(separator: ";")
        return chainString
	}
    
// Computed ========================================================================================
    public var isEmpty: Bool { tokenKeys.isEmpty }
    
// Methods =========================================================================================
    func post(key: TokenKey) { tokenKeys.append(key) }
    func removeKey() { tokenKeys.removeLast() }
    public func compile() -> ChainExe { ChainExe(chain: self) }

// ChainExe ======================================================================================
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

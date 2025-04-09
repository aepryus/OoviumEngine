//
//  Token.swift
//  Oovium
//
//  Created by Joe Charlier on 10/1/16.
//  Copyright © 2016 Aepryus Software. All rights reserved.
//

/* ======================================================================================
Token is the atomic unit of entry in Oovium; it works in concert with Chain.  The key
is constructed from the token code and the tag: "code:tag".  Tokens are obtained from
the Token static registry or from an aether.  Each key is unique within the token registry.

The tag is the unique identifier of the various Token types, such as a function name.
For Functions and Operators each tag will map to one or more Morphs.  When compiling
the chain the specific Morph will be chosen based on the Types of the input parameters.

parse is the exact string that is used to build up the string to be sent on to Chain.
Often parse and tag are equal, but for Variables in particular will have the type name
appended to it in order to allow Chain to select the appropriate Morph.

display is the string representing the Token that is to appear to the user on screen.
Mostly, this the same as tag and parse, but for Variable it could be the Variable's
user defined name or else it's formatted value.

- jjc 11/5/2010
====================================================================================== */

import Acheron
import Foundation

public class Token: Hashable {
    public enum Code: CaseIterable { case dg, ch, sp, cn, un, op, fn, ml, va, pr, cl }

    public var tag: String

    fileprivate init(tag: String) { self.tag = tag }

    public var code: Code { fatalError() }
    public var key: String { "\(code):\(tag)" }
    public var display: String { tag }

// Hashable ========================================================================================
    public static func == (left: Token, right: Token) -> Bool { left.key == right.key }
    public func hash(into hasher: inout Hasher) { hasher.combine(key) }

// Static ==========================================================================================
    static var tokens: [String:Token] = [:]
    static let aliases: [String:String] = ["-":"−", "*":"×", "/":"÷" ]

    // These are used by ChainResponder for handling external keyboards - jjc 10/27/22
    public static func digitToken(tag: String) -> DigitToken { tokens["\(Code.dg):\(tag)"]! as! DigitToken }
    public static func separatorToken(tag: String) -> SeparatorToken { tokens["\(Code.sp):\(tag)"]! as! SeparatorToken }
    public static func operatorToken(tag: String) -> OperatorToken { tokens["\(Code.op):\(aliases[tag] ?? tag)"]! as! OperatorToken }
    public static func characterToken(tag: String) -> CharacterToken { tokens["\(Code.ch):\(tag)"] as? CharacterToken ?? {
        let token = CharacterToken(tag: tag)
        tokens[token.key] = token
        return token
    }() }
    // This is only used by Anain to create variables when parsing natural.  I'm adding this while working on the test cases.
    // I'm not sure where this is going, but it can be deleted if causing problems later.
    public static func variableToken(tag: String) -> VariableToken { tokens["\(Code.va):\(tag)"] as? VariableToken ?? {
        let token = VariableToken(tag: tag)
        tokens[token.key] = token
        return token
    }() }

    // This is used by Aether.onLoad to initialize all the chains - jjc 10/27/22
    static func token(key: String) -> Token? {
        if let token: Token = tokens[key] { return token }
        guard key.count > 3 else { return nil }
        if key[0...1] == "\(Code.ch)" { return characterToken(tag: key[3...]) }
        if key[0...1] == "\(Code.va)" { return variableToken(tag: key[3...]) }
        return nil
    }

    public static let period: DigitToken            = DigitToken(tag: ".")
    public static let zero: DigitToken              = DigitToken(tag: "0")
    public static let one: DigitToken               = DigitToken(tag: "1")
    public static let two: DigitToken               = DigitToken(tag: "2")
    public static let three: DigitToken             = DigitToken(tag: "3")
    public static let four: DigitToken              = DigitToken(tag: "4")
    public static let five: DigitToken              = DigitToken(tag: "5")
    public static let six: DigitToken               = DigitToken(tag: "6")
    public static let seven: DigitToken             = DigitToken(tag: "7")
    public static let eight: DigitToken             = DigitToken(tag: "8")
    public static let nine: DigitToken              = DigitToken(tag: "9")

    public static let e: ConstantToken              = ConstantToken(tag:"e")
    public static let i: ConstantToken              = ConstantToken(tag:"i")
    public static let pi: ConstantToken             = ConstantToken(tag:"π")
    public static let yes: ConstantToken            = ConstantToken(tag:"true")
    public static let no: ConstantToken             = ConstantToken(tag:"false")
    
    public static let k: KToken                     = KToken()

    public static let add: OperatorToken            = OperatorToken(tag:"+", level: .add)
    public static let subtract: OperatorToken       = OperatorToken(tag:"−", level: .add)
    public static let multiply: OperatorToken       = OperatorToken(tag:"×", level: .multiply)
    public static let divide: OperatorToken         = OperatorToken(tag:"÷", level: .multiply)
    public static let dot: OperatorToken            = OperatorToken(tag:"•", level: .multiply)
    public static let mod: OperatorToken            = OperatorToken(tag:"%", level: .multiply)
    public static let power: OperatorToken          = OperatorToken(tag:"^", level: .power)
    public static let equal: OperatorToken          = OperatorToken(tag:"=", alias: " == ", level: .compare)
    public static let less: OperatorToken           = OperatorToken(tag:"<", alias: " < ", level: .compare)
    public static let greater: OperatorToken        = OperatorToken(tag:">", alias: " > ", level: .compare)
    public static let notEqual: OperatorToken       = OperatorToken(tag:"≠", alias: " ≠ ", level: .compare)
    public static let lessOrEqual: OperatorToken    = OperatorToken(tag:"≤", alias: " ≤ ", level: .compare)
    public static let greaterOrEqual: OperatorToken = OperatorToken(tag:"≥", alias: " ≥ ", level: .compare)
    public static let and: OperatorToken            = OperatorToken(tag:"&&", alias: " && ", level: .gate)
    public static let or: OperatorToken             = OperatorToken(tag:"||", alias: " || ", level: .gate)
    public static let not: UnaryToken               = UnaryToken(tag:"!")
    public static let neg: UnaryToken               = UnaryToken(tag:"−")

    public static let leftParen: SeparatorToken     = SeparatorToken(tag:"(")
    public static let comma: SeparatorToken         = SeparatorToken(tag:",")
    public static let rightParen: SeparatorToken    = SeparatorToken(tag:")")
    public static let bra: SeparatorToken           = SeparatorToken(tag:"[")
    public static let ket: SeparatorToken           = SeparatorToken(tag:"]")
    public static let quote: SeparatorToken         = SeparatorToken(tag:"\"")

    public static let abs: FunctionToken            = FunctionToken(tag: "abs")
    public static let round: FunctionToken          = FunctionToken(tag: "round")
    public static let floor: FunctionToken          = FunctionToken(tag: "floor")
    public static let sqrt: FunctionToken           = FunctionToken(tag: "sqrt")
    public static let fac: FunctionToken            = FunctionToken(tag: "fac")
    public static let exp: FunctionToken            = FunctionToken(tag: "exp")
    public static let ln: FunctionToken             = FunctionToken(tag: "ln")
    public static let log: FunctionToken            = FunctionToken(tag: "log")
    public static let tenth: FunctionToken          = FunctionToken(tag: "ten")
    public static let second: FunctionToken         = FunctionToken(tag: "two")
    public static let log2: FunctionToken           = FunctionToken(tag: "log2")
    public static let sin: FunctionToken            = FunctionToken(tag: "sin")
    public static let cos: FunctionToken            = FunctionToken(tag: "cos")
    public static let tan: FunctionToken            = FunctionToken(tag: "tan")
    public static let asin: FunctionToken           = FunctionToken(tag: "asin")
    public static let acos: FunctionToken           = FunctionToken(tag: "acos")
    public static let atan: FunctionToken           = FunctionToken(tag: "atan")
    public static let sec: FunctionToken            = FunctionToken(tag: "sec")
    public static let csc: FunctionToken            = FunctionToken(tag: "csc")
    public static let cot: FunctionToken            = FunctionToken(tag: "cot")
    public static let sinh: FunctionToken           = FunctionToken(tag: "sinh")
    public static let cosh: FunctionToken           = FunctionToken(tag: "cosh")
    public static let tanh: FunctionToken           = FunctionToken(tag: "tanh")
    public static let asinh: FunctionToken          = FunctionToken(tag: "asinh")
    public static let acosh: FunctionToken          = FunctionToken(tag: "acosh")
    public static let atanh: FunctionToken          = FunctionToken(tag: "atanh")
    public static let random: FunctionToken         = FunctionToken(tag: "random")
    public static let iif: FunctionToken            = FunctionToken(tag: "if", params: 3)
    public static let min: FunctionToken            = FunctionToken(tag: "min", params: 2)
    public static let max: FunctionToken            = FunctionToken(tag: "max", params: 2)
    public static let sum: FunctionToken            = FunctionToken(tag: "∑", params: 3)
    public static let complex: FunctionToken        = FunctionToken(tag: "Complex", params: 2)
    public static let vector: FunctionToken         = FunctionToken(tag: "Vector", params: 3)

    public static let chill: ConstantToken          = ConstantToken(tag: "chill")
    public static let eat: ConstantToken            = ConstantToken(tag: "eat")
    public static let flirt: ConstantToken          = ConstantToken(tag: "flirt")
    public static let fight: ConstantToken          = ConstantToken(tag: "fight")
    public static let flee: ConstantToken           = ConstantToken(tag: "flee")
    public static let wander: ConstantToken         = ConstantToken(tag: "wander")
    
    static func start() {
        [   period, zero, one, two, three, four, five, six, seven, eight, nine, e, i, pi, yes, no,
            k, add, subtract, multiply, divide, dot, mod, power, equal, less, greater, notEqual,
            lessOrEqual, greaterOrEqual, and, or, not, neg, leftParen, comma, rightParen, bra, ket,
            quote, abs, round, floor, sqrt, fac, exp, ln, log, tenth, second, log2, sin, cos, tan,
            asin, acos, atan, sec, csc, cot, sinh, cosh, tanh, asinh, acosh, atanh, random, iif,
            min, max, sum, complex, vector, chill, eat, flirt, fight, flee, wander
        ].forEach { tokens[$0.key] = $0 }
    }
}

public protocol Paramsable: Token { var params: Int { get set } }
public protocol Defable: Token { var def: Def? { get set } }

public class DigitToken: Token {
    override public var code: Code { .dg }
}
public class CharacterToken: Token {
    override public var code: Code { .ch }
}
public class SeparatorToken: Token {
    override public var code: Code { .sp }
}
public class UnaryToken: Token {
    override public var code: Code { .un }
}
public class ConstantToken: Token, Defable {
	public var def: Def? = nil
    override public var code: Code { .cn }
}
public class KToken: Token {
    public init() { super.init(tag: "k") }
    override public var code: Code { .va }
}
public class OperatorToken: Token {
    public enum Level: Int { case add, multiply, power, compare, gate }
	public var alias: String?
	public let level: Level
	init(tag: String, alias: String? = nil, level: Level) {
		self.alias = alias
		self.level = level
		super.init(tag: tag)
	}
    override public var code: Code { .op }
	public override var display: String { alias ?? tag }
}
public class FunctionToken: Token, Defable, Paramsable {
    public var def: Def?
    public var params: Int
    init(tag: String, params: Int = 1) {
        self.params = params
        super.init(tag: tag)
    }
    override public var code: Code { .fn }
    public override var display: String { "\(tag)(" }
}

public class TowerToken: Token, Defable {
    public enum Status { case ok, invalid, deleted, blocked }
    public weak var tower: Tower!
    public var status: Status = .ok
    public var def: Def? = nil
    fileprivate init(tower: Tower?, tag: String) {
        self.tower = tower
        super.init(tag: tag)
    }
}

protocol VariableTokenDelegate: AnyObject {
    var alias: String? { get }
}
public class StaticVariableTokenDelegate: VariableTokenDelegate {
    var alias: String?
    init (_ alias: String) { self.alias = alias }
}

public class VariableToken: TowerToken {
    weak var delegate: VariableTokenDelegate?
    var alias: String? { delegate?.alias }
    var details: String?
    init(tower: Tower? = nil, tag: String, delegate: VariableTokenDelegate? = nil) {
        self.delegate = delegate
        super.init(tower: tower, tag: tag)
    }
    
    public var value: String? { tower?.obje.display ?? "DELETED" }
    
// Tower ===========================================================================================
    override public var code: Code { .va }
    public override var display: String { details ?? alias ?? value ?? tag }
}
public class ColumnToken: VariableToken {
// Tower ===========================================================================================
    override public var code: Code { .cl }
}
//public class PropertyToken: TowerToken {
//    public var label: String?
//    init(tower: Tower? = nil, tag: String, label: String? = nil) {
//        self.label = label
//        super.init(tower: tower, tag: tag)
//    }
//    override public var code: Code { .pr }
//    public override var display: String { label ?? tag }
//}
public class MechlikeToken: TowerToken, Paramsable {
    weak var delegate: VariableTokenDelegate?
    var alias: String? { delegate?.alias }
	public var params: Int = 1
    init(tower: Tower? = nil, tag: String, delegate: VariableTokenDelegate? = nil) {
        self.delegate = delegate
        super.init(tower: tower, tag: tag)
	}
    override public var code: Code { .ml }
	public override var display: String { "\(alias ?? tag)(" }
}

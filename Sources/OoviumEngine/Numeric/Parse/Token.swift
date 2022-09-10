//
//  Token.swift
//  Oovium
//
//  Created by Joe Charlier on 10/1/16.
//  Copyright © 2016 Aepryus Software. All rights reserved.
//

/* ======================================================================================
Token is the atomic unit of entry in Oovium; it works in concert with Chain.  The key
is constructed from the token type and the tag: "type:tag".  Tokens are obtained from
the Token static registry.  Each key is unique within the token registry.

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

import Foundation

public enum TokenType: Int {
	case digit, `operator`, separator, function, variable, property, constant, character, unary
}
public enum TokenLevel: Int {
	case add, multiply, power, compare, gate
}
public enum TokenStatus {
	case ok, invalid, deleted, blocked
}

public protocol Labelable: Token { var label: String { get set } }
public protocol Paramsable: Token { var params: Int { get set } }
public protocol Levelable: Token { var level: TokenLevel { get } }
public protocol Defable: Token { var def: Def? { get set } }

public class TowerToken: Token, Labelable, Defable {
	public var label: String
	public var def: Def? = nil

	fileprivate init(type: TokenType, tag: String, label: String? = nil) {
		self.label = label ?? tag
		super.init(type: type, tag: tag)
	}
}

public class DigitToken: Token {
	init(tag: String) { super.init(type: .digit, tag: tag) }
}
public class CharacterToken: Token {
	init(tag: String) { super.init(type: .character, tag: tag) }
}
public class SeparatorToken: Token {
	init(tag: String) { super.init(type: .separator, tag: tag) }
}
public class ConstantToken: Token, Defable {
	public var def: Def? = nil

	init(tag: String) {
		super.init(type: .constant, tag: tag)
	}
}
public class UnaryToken: Token {
	init(tag: String) {
		super.init(type: .unary, tag: tag)
	}
}
public class OperatorToken: Token, Labelable, Levelable {
	public var label: String
	public let level: TokenLevel

	init(tag: String, level: TokenLevel, label: String? = nil) {
		self.label = label ?? tag
		self.level = level
		super.init(type: .operator, tag: tag)
	}
	public override var display: String { return label }
}
public class FunctionToken: TowerToken, Paramsable {
	public var params: Int
	let recipe: String?
	init(tag: String, label: String? = nil, params: Int = 1, recipe: String? = nil) {
		self.params = params
		self.recipe = recipe
		super.init(type: .function, tag: tag, label: label)
	}
	public override var display: String { "\(tag)(" }
}
public class VariableToken: TowerToken {
	init(tag: String, label: String? = nil) {
		super.init(type: .variable, tag: tag, label: label)
	}
	public override var display: String { return label }
}
public class PropertyToken: TowerToken {
	init(tag: String, label: String? = nil) {
		super.init(type: .property, tag: tag)
	}
}

public class Token: Hashable {
	public let type: TokenType
	var tag: String

	public var status: TokenStatus = .ok

	fileprivate init(type: TokenType, tag: String) {
		self.type = type
		self.tag = tag
	}

	var key: String { "\(type.rawValue):\(tag)" }
	public var display: String { return tag }

// Hashable ========================================================================================
	public static func == (left: Token, right: Token) -> Bool {
		return left === right
	}
	public func hash(into hasher: inout Hasher) {
		 hasher.combine(ObjectIdentifier(self))
	}

// Static ==========================================================================================
	static var tokens: [String:Token] = [:]

	static func register(token: Token) { tokens[token.key] = token }

	public static func digitToken(tag: String) -> DigitToken { tokens["\(TokenType.digit.rawValue):\(tag)"]! as! DigitToken }
	public static func characterToken(tag: String) -> CharacterToken {
		return tokens["\(TokenType.character.rawValue):\(tag)"] as? CharacterToken ?? {
			let token = CharacterToken(tag: tag)
			register(token: token)
			return token
		}()
	}
	public static func separatorToken(tag: String) -> SeparatorToken { tokens["\(TokenType.separator.rawValue):\(tag)"]! as! SeparatorToken }
	public static func operatorToken(tag: String) -> OperatorToken { tokens["\(TokenType.operator.rawValue):\(aliases[tag] ?? tag)"]! as! OperatorToken }

	static let aliases: [String:String] = ["-":"−", "*":"×", "/":"÷" ]
	static func token(key: String) -> Token? {
        guard key != "7::" else { return tokens[key] ?? characterToken(tag: ":") }
		let subs: [Substring] = key.split(separator: ":")
		let s0: Int = Int(String(subs[0]))!
		let s1: String = String(subs[1])
		let type: TokenType = TokenType(rawValue: s0)!
		let tag: String = Token.aliases[s1] ?? s1
		let key: String = "\(type.rawValue):\(tag)"

		let token: Token? = tokens[key]
		if let token = token { return token }

		guard type == .character else { return nil }
		return characterToken(tag: tag)
	}

	static func buildTokens(chain: Chain) {
		guard let keys = chain.loadedKeys else { return }
		keys.forEach { chain.tokens.append(token(key: $0)!) }
		chain.loadedKeys = nil
	}

	public static let period: DigitToken			= DigitToken(tag: ".")
	public static let zero: DigitToken				= DigitToken(tag: "0")
	public static let one: DigitToken				= DigitToken(tag: "1")
	public static let two: DigitToken				= DigitToken(tag: "2")
	public static let three: DigitToken				= DigitToken(tag: "3")
	public static let four: DigitToken				= DigitToken(tag: "4")
	public static let five: DigitToken				= DigitToken(tag: "5")
	public static let six: DigitToken				= DigitToken(tag: "6")
	public static let seven: DigitToken				= DigitToken(tag: "7")
	public static let eight: DigitToken				= DigitToken(tag: "8")
	public static let nine: DigitToken				= DigitToken(tag: "9")

	public static let e: ConstantToken				= ConstantToken(tag:"e")
	public static let i: ConstantToken				= ConstantToken(tag:"i")
	public static let pi: ConstantToken				= ConstantToken(tag:"π")
	public static let yes: ConstantToken			= ConstantToken(tag:"true")
	public static let no: ConstantToken				= ConstantToken(tag:"false")

	public static let add: OperatorToken			= OperatorToken(tag:"+", level: .add)
	public static let subtract: OperatorToken		= OperatorToken(tag:"−", level: .add)
	public static let multiply: OperatorToken		= OperatorToken(tag:"×", level: .multiply)
	public static let divide: OperatorToken			= OperatorToken(tag:"÷", level: .multiply)
	public static let dot: OperatorToken			= OperatorToken(tag:"•", level: .multiply)
	public static let mod: OperatorToken			= OperatorToken(tag:"%", level: .multiply)
	public static let power: OperatorToken			= OperatorToken(tag:"^", level: .power)
	public static let equal: OperatorToken			= OperatorToken(tag:"=", level: .compare, label: " == ")
	public static let less: OperatorToken			= OperatorToken(tag:"<", level: .compare, label: " < ")
	public static let greater: OperatorToken		= OperatorToken(tag:">", level: .compare, label: " > ")
	public static let notEqual: OperatorToken		= OperatorToken(tag:"≠", level: .compare, label: " ≠ ")
	public static let lessOrEqual: OperatorToken	= OperatorToken(tag:"≤", level: .compare, label: " ≤ ")
	public static let greaterOrEqual: OperatorToken	= OperatorToken(tag:"≥", level: .compare, label: " ≥ ")
	public static let and: OperatorToken			= OperatorToken(tag:"&&", level: .gate, label: " && ")
	public static let or: OperatorToken				= OperatorToken(tag:"||", level: .gate, label: " || ")
	public static let not: UnaryToken				= UnaryToken(tag:"!")
	public static let neg: UnaryToken				= UnaryToken(tag:"−")

	public static let leftParen: SeparatorToken		= SeparatorToken(tag:"(")
	public static let comma: SeparatorToken			= SeparatorToken(tag:",")
	public static let rightParen: SeparatorToken	= SeparatorToken(tag:")")
	public static let bra: SeparatorToken			= SeparatorToken(tag:"[")
	public static let ket: SeparatorToken			= SeparatorToken(tag:"]")
	public static let quote: SeparatorToken			= SeparatorToken(tag:"\"")

	public static let abs: FunctionToken			= FunctionToken(tag: "abs")
	public static let round: FunctionToken			= FunctionToken(tag: "round")
	public static let floor: FunctionToken			= FunctionToken(tag: "floor")
	public static let sqrt: FunctionToken			= FunctionToken(tag: "sqrt")
	public static let fac: FunctionToken			= FunctionToken(tag: "fac")
	public static let exp: FunctionToken			= FunctionToken(tag: "exp")
	public static let ln: FunctionToken				= FunctionToken(tag: "ln")
	public static let log: FunctionToken			= FunctionToken(tag: "log")
	public static let tenth: FunctionToken			= FunctionToken(tag: "ten")
	public static let second: FunctionToken			= FunctionToken(tag: "two")
	public static let log2: FunctionToken			= FunctionToken(tag: "log2")
	public static let sin: FunctionToken			= FunctionToken(tag: "sin")
	public static let cos: FunctionToken			= FunctionToken(tag: "cos")
	public static let tan: FunctionToken			= FunctionToken(tag: "tan")
	public static let asin: FunctionToken			= FunctionToken(tag: "asin")
	public static let acos: FunctionToken			= FunctionToken(tag: "acos")
	public static let atan: FunctionToken			= FunctionToken(tag: "atan")
	public static let sec: FunctionToken			= FunctionToken(tag: "sec")
	public static let csc: FunctionToken			= FunctionToken(tag: "csc")
	public static let cot: FunctionToken			= FunctionToken(tag: "cot")
	public static let sinh: FunctionToken			= FunctionToken(tag: "sinh")
	public static let cosh: FunctionToken			= FunctionToken(tag: "cosh")
	public static let tanh: FunctionToken			= FunctionToken(tag: "tanh")
	public static let asinh: FunctionToken			= FunctionToken(tag: "asinh")
	public static let acosh: FunctionToken			= FunctionToken(tag: "acosh")
	public static let atanh: FunctionToken			= FunctionToken(tag: "atanh")
	public static let random: FunctionToken			= FunctionToken(tag: "random")
	public static let iif: FunctionToken			= FunctionToken(tag: "if", params: 3)
	public static let min: FunctionToken			= FunctionToken(tag: "min", params: 2)
	public static let max: FunctionToken			= FunctionToken(tag: "max", params: 2)
	public static let sum: FunctionToken			= FunctionToken(tag: "∑", params: 3)
	public static let complex: FunctionToken		= FunctionToken(tag: "Complex", params: 2)
	public static let vector: FunctionToken			= FunctionToken(tag: "Vector", params: 3)

	public static let k: VariableToken				= VariableToken(tag:"k")

	public static let chill: ConstantToken			= ConstantToken(tag:"chill")
	public static let eat: ConstantToken			= ConstantToken(tag:"eat")
	public static let flirt: ConstantToken			= ConstantToken(tag:"flirt")
	public static let fight: ConstantToken			= ConstantToken(tag:"fight")
	public static let flee: ConstantToken			= ConstantToken(tag:"flee")
	public static let wander: ConstantToken			= ConstantToken(tag:"wander")
}

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
enum TokenStatus {
	case ok, invalid, deleted, blocked
}

protocol Labelable: Token { var label: String { get set } }
protocol Paramsable: Token { var params: Int { get set } }
protocol Levelable: Token { var level: TokenLevel { get } }
protocol Defable: Token { var def: Def? { get set } }

class TowerToken: Token, Labelable, Defable {
	var label: String
	var def: Def? = nil

	fileprivate init(type: TokenType, tag: String, label: String? = nil) {
		self.label = label ?? tag
		super.init(type: type, tag: tag)
	}
}

class DigitToken: Token {
	init(tag: String) { super.init(type: .digit, tag: tag) }
}
class CharacterToken: Token {
	init(tag: String) { super.init(type: .character, tag: tag) }
}
class SeparatorToken: Token {
	init(tag: String) { super.init(type: .separator, tag: tag) }
}
class ConstantToken: Token, Defable {
	var def: Def? = nil

	init(tag: String) {
		super.init(type: .constant, tag: tag)
	}
}
class UnaryToken: Token {
	init(tag: String) {
		super.init(type: .unary, tag: tag)
	}
}
class OperatorToken: Token, Labelable, Levelable {
	var label: String
	let level: TokenLevel

	init(tag: String, level: TokenLevel, label: String? = nil) {
		self.label = label ?? tag
		self.level = level
		super.init(type: .operator, tag: tag)
	}
	override var display: String { return label }
}
class FunctionToken: TowerToken, Paramsable {
	var params: Int
	let recipe: String?
	init(tag: String, label: String? = nil, params: Int = 1, recipe: String? = nil) {
		self.params = params
		self.recipe = recipe
		super.init(type: .function, tag: tag, label: label)
	}
	override var display: String { "\(tag)(" }
}
class VariableToken: TowerToken {
	init(tag: String, label: String? = nil) {
		super.init(type: .variable, tag: tag, label: label)
	}
	override var display: String { return label }
}
class PropertyToken: TowerToken {
	init(tag: String, label: String? = nil) {
		super.init(type: .property, tag: tag)
	}
}

class Token: Hashable {
	let type: TokenType
	var tag: String

	var status: TokenStatus = .ok

	fileprivate init(type: TokenType, tag: String) {
		self.type = type
		self.tag = tag
	}

	var key: String { "\(type.rawValue):\(tag)" }
	var display: String { return tag }

// Hashable ========================================================================================
	static func == (left: Token, right: Token) -> Bool {
		return left === right
	}
	func hash(into hasher: inout Hasher) {
		 hasher.combine(ObjectIdentifier(self))
	}

// Static ==========================================================================================
	static var tokens: [String:Token] = [:]

	static func register(token: Token) { tokens[token.key] = token }

	static func digitToken(tag: String) -> DigitToken { tokens["\(TokenType.digit.rawValue):\(tag)"]! as! DigitToken }
	static func characterToken(tag: String) -> CharacterToken {
		return tokens["\(TokenType.character.rawValue):\(tag)"] as? CharacterToken ?? {
			let token = CharacterToken(tag: tag)
			register(token: token)
			return token
		}()
	}
	static func separatorToken(tag: String) -> SeparatorToken { tokens["\(TokenType.separator.rawValue):\(tag)"]! as! SeparatorToken }
	static func operatorToken(tag: String) -> OperatorToken { tokens["\(TokenType.operator.rawValue):\(aliases[tag] ?? tag)"]! as! OperatorToken }

	static let aliases: [String:String] = ["-":"−", "*":"×", "/":"÷" ]
	static func token(key: String) -> Token? {
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

	static let period: DigitToken				= DigitToken(tag: ".")
	static let zero: DigitToken					= DigitToken(tag: "0")
	static let one: DigitToken					= DigitToken(tag: "1")
	static let two: DigitToken					= DigitToken(tag: "2")
	static let three: DigitToken				= DigitToken(tag: "3")
	static let four: DigitToken					= DigitToken(tag: "4")
	static let five: DigitToken					= DigitToken(tag: "5")
	static let six: DigitToken					= DigitToken(tag: "6")
	static let seven: DigitToken				= DigitToken(tag: "7")
	static let eight: DigitToken				= DigitToken(tag: "8")
	static let nine: DigitToken					= DigitToken(tag: "9")

	static let e: ConstantToken					= ConstantToken(tag:"e")
	static let i: ConstantToken					= ConstantToken(tag:"i")
	static let pi: ConstantToken				= ConstantToken(tag:"π")
	static let yes: ConstantToken				= ConstantToken(tag:"true")
	static let no: ConstantToken				= ConstantToken(tag:"false")

	static let add: OperatorToken				= OperatorToken(tag:"+", level: .add)
	static let subtract: OperatorToken			= OperatorToken(tag:"−", level: .add)
	static let multiply: OperatorToken			= OperatorToken(tag:"×", level: .multiply)
	static let divide: OperatorToken			= OperatorToken(tag:"÷", level: .multiply)
	static let dot: OperatorToken				= OperatorToken(tag:"•", level: .multiply)
	static let mod: OperatorToken				= OperatorToken(tag:"%", level: .multiply)
	static let power: OperatorToken				= OperatorToken(tag:"^", level: .power)
	static let equal: OperatorToken				= OperatorToken(tag:"=", level: .compare, label: " == ")
	static let less: OperatorToken				= OperatorToken(tag:"<", level: .compare, label: " < ")
	static let greater: OperatorToken			= OperatorToken(tag:">", level: .compare, label: " > ")
	static let notEqual: OperatorToken			= OperatorToken(tag:"≠", level: .compare, label: " ≠ ")
	static let lessOrEqual: OperatorToken		= OperatorToken(tag:"≤", level: .compare, label: " ≤ ")
	static let greaterOrEqual: OperatorToken	= OperatorToken(tag:"≥", level: .compare, label: " ≥ ")
	static let and: OperatorToken				= OperatorToken(tag:"&&", level: .gate, label: " && ")
	static let or: OperatorToken				= OperatorToken(tag:"||", level: .gate, label: " || ")
	static let not: UnaryToken					= UnaryToken(tag:"!")
	static let neg: UnaryToken					= UnaryToken(tag:"−")

	static let leftParen: SeparatorToken		= SeparatorToken(tag:"(")
	static let comma: SeparatorToken			= SeparatorToken(tag:",")
	static let rightParen: SeparatorToken		= SeparatorToken(tag:")")
	static let bra: SeparatorToken				= SeparatorToken(tag:"[")
	static let ket: SeparatorToken				= SeparatorToken(tag:"]")
	static let quote: SeparatorToken			= SeparatorToken(tag:"\"")

	static let abs: FunctionToken				= FunctionToken(tag: "abs")
	static let round: FunctionToken				= FunctionToken(tag: "round")
	static let floor: FunctionToken				= FunctionToken(tag: "floor")
	static let sqrt: FunctionToken				= FunctionToken(tag: "sqrt")
	static let fac: FunctionToken				= FunctionToken(tag: "fac")
	static let exp: FunctionToken				= FunctionToken(tag: "exp")
	static let ln: FunctionToken				= FunctionToken(tag: "ln")
	static let log: FunctionToken				= FunctionToken(tag: "log")
	static let tenth: FunctionToken				= FunctionToken(tag: "ten")
	static let second: FunctionToken			= FunctionToken(tag: "two")
	static let log2: FunctionToken				= FunctionToken(tag: "log2")
	static let sin: FunctionToken				= FunctionToken(tag: "sin")
	static let cos: FunctionToken				= FunctionToken(tag: "cos")
	static let tan: FunctionToken				= FunctionToken(tag: "tan")
	static let asin: FunctionToken				= FunctionToken(tag: "asin")
	static let acos: FunctionToken				= FunctionToken(tag: "acos")
	static let atan: FunctionToken				= FunctionToken(tag: "atan")
	static let sec: FunctionToken				= FunctionToken(tag: "sec")
	static let csc: FunctionToken				= FunctionToken(tag: "csc")
	static let cot: FunctionToken				= FunctionToken(tag: "cot")
	static let sinh: FunctionToken				= FunctionToken(tag: "sinh")
	static let cosh: FunctionToken				= FunctionToken(tag: "cosh")
	static let tanh: FunctionToken				= FunctionToken(tag: "tanh")
	static let asinh: FunctionToken				= FunctionToken(tag: "asinh")
	static let acosh: FunctionToken				= FunctionToken(tag: "acosh")
	static let atanh: FunctionToken				= FunctionToken(tag: "atanh")
	static let random: FunctionToken			= FunctionToken(tag: "random")
	static let iif: FunctionToken				= FunctionToken(tag: "if", params: 3)
	static let min: FunctionToken				= FunctionToken(tag: "min", params: 2)
	static let max: FunctionToken				= FunctionToken(tag: "max", params: 2)
	static let sum: FunctionToken				= FunctionToken(tag: "∑", params: 3)
	static let complex: FunctionToken			= FunctionToken(tag: "Complex", params: 2)
	static let vector: FunctionToken			= FunctionToken(tag: "Vector", params: 3)

	static let k: VariableToken					= VariableToken(tag:"k")

	static let chill: ConstantToken				= ConstantToken(tag:"chill")
	static let eat: ConstantToken				= ConstantToken(tag:"eat")
	static let flirt: ConstantToken				= ConstantToken(tag:"flirt")
	static let fight: ConstantToken				= ConstantToken(tag:"fight")
	static let flee: ConstantToken				= ConstantToken(tag:"flee")
	static let wander: ConstantToken			= ConstantToken(tag:"wander")
}

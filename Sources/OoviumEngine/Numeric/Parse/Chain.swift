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

fileprivate class Ops {
	unowned private let chain: Chain
	
	weak private var pOp: OperatorToken?
	weak private var mOp: OperatorToken?
	weak private var aOp: OperatorToken?
	weak private var cOp: OperatorToken?
	weak private var gOp: OperatorToken?
	
	init(_ chain: Chain) {
		self.chain = chain
	}
	
	private func doPOP(_ token: OperatorToken?) throws {
		if let pOp = pOp { try chain.apply(token: pOp) }
		pOp = token
	}
	private func doMOP(_ token: OperatorToken?) throws {
		if let mOp = mOp { try chain.apply(token: mOp) }
		mOp = token
	}
	private func doAOP(_ token: OperatorToken?) throws {
		if let aOp = aOp { try chain.apply(token: aOp) }
		aOp = token
	}
	private func doCOP(_ token: OperatorToken?) throws {
		if let cOp = cOp { try chain.apply(token: cOp) }
		cOp = token
	}
	private func doGOP(_ token: OperatorToken?) throws {
		if let gOp = gOp { try chain.apply(token: gOp) }
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

enum ParseError: Error {
	case general
}

public final class Chain: NSObject, Packable, TowerDelegate {
	public var tokens: [Token] = []
	public var tower: Tower!
	
	public private(set) var editing: Bool = false
	public var cursor: Int = 0
	var alwaysShow: Bool = false

	var loadedKeys: [String]? = nil

	public override init() {}
	public init(tokens: [Token]) {
		guard tokens.count > 0 else { return }
		self.tokens = tokens
		cursor = self.tokens.count
	}
	public convenience init(natural: String) {
		let keys: [String] = Chain.convert(natural: natural)
		self.init()
		loadedKeys = keys
		cursor = keys.count
	}

// Packable ========================================================================================
	public init(_ tokensString: String) {
		guard !tokensString.isEmpty else { return }
		loadedKeys = tokensString.components(separatedBy: ";")
		cursor = loadedKeys!.count
	}
	public func pack() -> String {
		var sb: String = ""
		tokens.forEach { sb.append("\($0.key);") }
		if sb.count > 0 { sb.remove(at: sb.index(before: sb.endIndex)) }
		return sb
	}
	
// Private =========================================================================================
    private func buildTokens() {
        tokens = loadedKeys?.map({ Token.token(key: $0)! }) ?? []
        loadedKeys = nil
    }
    
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
	private static func convert(natural: String) -> [String] {
		var isStart: Bool = true
		var keys: [String] = []
		var i: Int = 0
		while i < natural.count {
            var tag: String = Token.aliases["\(natural[i])"] ?? "\(natural[i])"
            let code: Token.Code
            if natural[i].isWholeNumber { code = .dg }
			else if natural[i] == "!" { code = .un }
			else if natural[i] == "-" && isStart { code = .un }
			else if ["+", "-", "*", "/", "^"].contains(natural[i]) { code = .op }
			else if ["(", ",", ")"].contains(natural[i]) { code = .sp }
			else if ["e", "i", "π"].contains(natural[i]) { code = .cn }
			else if natural[i] == "\"" {
                keys.append("\(Token.Code.sp):\"")
				i += 1
				let end: Int = natural.loc(of: "\"", after: i)!
				while i < end {
                    keys.append("\(Token.Code.ch):\(natural[i])")
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
	
// Public ==========================================================================================
	public var tokensString: String {
		return ""
	}
	public var natural: String {
		return ""
	}

	public func edit() {
		editing = true
		cursor = tokens.count
        tower.listener?.onTriggered()
        AETaskRelease(tower.task)
        tower.task = AETaskCreateNull()
	}
	public func ok() {
		editing = false
		tower.buildTask()
		tower.trigger()
	}
	
	public func attemptToPost(token: Token) -> Bool {
		
        if let this = tower, let towerToken = token as? TowerToken {
            let that: Tower = towerToken.tower
			if this.downstream(contains: that) { return false }
			if let thisWeb = this.web ?? this.tailForWeb, let thatWeb = that.web {
				if thisWeb !== thatWeb { return false }
			}
			that.attach(this)
		}
		
		tokens.insert(token, at: cursor)
		
		cursor += 1

		return true
	}
	public func post(token: Token) {
		_ = attemptToPost(token: token)
	}
	public func minusSign() {
		post(token: minusToken())
	}
	public func parenthesis() {
		guard let parenToken = parenToken() else { return }
		post(token: parenToken)
	}
	public func braket() {
		guard let braketToken = braketToken() else { return }
		post(token: braketToken)
	}
	public func backspace() -> Token? {
		guard cursor > 0 else { return nil }
		cursor -= 1
		let token = tokens.remove(at: cursor)
        if let this: Tower = tower, let that: Tower = (token as? TowerToken)?.tower {
			if !tokens.contains(token) {that.detach(this)}
		}
		return token
	}
	public func delete() -> Token? {
		guard cursor < tokens.count else { return nil }
		let token = tokens.remove(at: cursor)
        if let this = tower, let towerToken = token as? TowerToken {
            let that: Tower = towerToken.tower
			if !tokens.contains(token) {that.detach(this)}
		}
		return token
	}
	public func leftArrow() -> Bool {
		guard cursor > 0 else { return false }
		cursor -= 1
		return true
	}
	public func rightArrow() -> Bool {
		guard cursor < tokens.count else { return false }
		cursor += 1
		return true
	}
	public var inString: Bool {
		var q: Int = 0
		for (i, token) in tokens.enumerated() {
			if i == cursor {break}
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
		cursor = 0
	}
	public func replaceWith(tokens: String) {
		let keys = tokens.components(separatedBy: ";")
		loadedKeys = keys
		cursor = keys.count
        buildTokens()
	}
	public func replaceWith(natural: String) {
		self.loadedKeys = Chain.convert(natural: natural)
		cursor = self.loadedKeys?.count ?? 0
	}

// Unknown =========================================================================================
	var tokensDisplay: String {
		var sb = String()
		tokens.forEach { sb.append($0.display) }
		return sb
	}
	
// Parsing =========================================================================================
	private var morphs = [Int]()
	var variables = [String]()
	private var constants = [Obje]()
	private var stack = [String](repeating: "", count: 10)
	private var sp = 0
	
	// Stack
	private func push(_ key: String) {
		stack[sp] = key;
		sp += 1
		if sp == 10 {sp = 0}
	}
	private func pop() -> String {
		sp -= 1
		if sp == -1 {sp = 9}
		return stack[sp]
	}
	private func peek() -> String {
		return stack[sp-1]
	}
	
	private func addMorph(_ morph: Int) {
		morphs.append(morph)
		if let morph = Morph(rawValue: morph) {
			push(morph.def.key)
		} else {
			push("num")
		}
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

	private func parseOperator(tokens:[Token], i:Int, ops:Ops) throws {
		if let token: OperatorToken = tokens[i] as? OperatorToken {
			switch token.level {
				case .add:			try ops.aOp(token)
				case .multiply:		try ops.mOp(token)
				case .power:		try ops.pOp(token)
				case .compare:		try ops.cOp(token)
				case .gate:			try ops.gOp(token)
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
	private func parseNumber(tokens: [Token], i: Int) -> String {
		var sb = String()
		for i in i..<tokens.count {
			let token = tokens[i]
			if token.code != .dg { break }
			sb.append(token.tag)
		}
		return sb;
	}
	private func parseChain(tokens: [Token], i: Int) throws -> [Token] {
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
	private func parseString(tokens: [Token], i: Int) throws -> String  {
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
	private func parseOperand(tokens: [Token], i: Int) throws -> Int {
		guard tokens.count > i else { throw ParseError.general }

		var i: Int = i
		var token: Token = tokens[i]

        // Fix for imported unary Tokens ========
        if tokens[i] === Token.subtract {
            self.tokens[i] = Token.neg
            token = Token.neg
        }
        // ======================================

		var unary: UnaryToken?
		if let ut = token as? UnaryToken {
			unary = ut
			i += 1
			if (i == tokens.count) { throw ParseError.general }
			token = tokens[i]
		}
		
		if token.code == .dg {
			let n: String = parseNumber(tokens:tokens, i:i)
			let x: Double = Double(n) ?? Double.nan
			try addConstant(Obje(AEObjReal(x)));
			if let unary = unary { try apply(token: unary) }
			return n.lengthOfBytes(using: .ascii) + (unary != nil ? 1 : 0)
		} else if token == .leftParen {
			i += 1
			let e = try findEnd(i)
			try parseTokens(tokens: tokens, start: i, stop: e)
			if let unary = unary { try apply(token: unary) }
			return 2 + e - i + (unary != nil ? 1 : 0)
        } else if let token = token as? FunctionToken {
            i += 1
            let e = try findEnd(i)
            try parseTokens(tokens: tokens, start: i, stop: e)
            try apply(token: token)
            if let unary = unary { try apply(token: unary) }
            return 2 + e - i + (unary != nil ? 1 : 0)
        } else if let token = token as? MechlikeToken {
            i += 1
            let e = try findEnd(i)
            try parseTokens(tokens: tokens, start: i, stop: e)
            variables.append(token.tag)
            addMorph(Morph.recipe.rawValue)
            if let unary = unary { try apply(token: unary) }
            return 2 + e - i + (unary != nil ? 1 : 0)
		} else if token == .bra {
			i += 1
			let tokens: [Token] = try parseChain(tokens: tokens, i: i)
			let chain: Chain = Chain(tokens: tokens)
			chain.tower = tower
			// The name sent to compile is used to set the lambda index vi, but since vi won't be used in this case I'm sending 'k' in just to ensure the name is found.
			// This needs to be cleaned up. 5/11/20
			try addConstant(Obje(AEObjLambda(chain.compile(name: "k"))))
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

			if token == Token.i {
				try addConstant(Obje.i)
			} else if token == Token.e {
				try addConstant(Obje.e)
			} else if token == Token.pi {
				try addConstant(Obje.pi)
			} else if token == Token.yes {
				try addConstant(Obje.yes)
			} else if token == Token.no {
				try addConstant(Obje.no)
			} else if token == Token.chill {
				try addConstant(Obje.chill)
			} else if token == Token.eat {
				try addConstant(Obje.eat)
			} else if token == Token.flirt {
				try addConstant(Obje.flirt)
			} else if token == Token.fight {
				try addConstant(Obje.fight)
			} else if token == Token.flee {
				try addConstant(Obje.flee)
			} else if token == Token.wander {
				try addConstant(Obje.wander)
			}

			if let unary = unary { try apply(token: unary) }
			return 1 + (unary != nil ? 1 : 0)

		} else if token == Token.quote {
			let text: String = try parseString(tokens: tokens, i: i)
			try addConstant(Obje(AEObjString(text.toInt8())))
			return text.count+2
		}
		
		throw ParseError.general
	}
	private func parseTokens(tokens:[Token], start:Int, stop:Int) throws {
		if tokens.count == 0 || start == stop { return }
		let ops: Ops = Ops(self)
		var i: Int = start
		i += try parseOperand(tokens:tokens, i:i)
		while i < stop {
			try parseOperator(tokens:tokens, i:i, ops:ops)
			i += 1
			i += try parseOperand(tokens:tokens, i:i)
		}
		try ops.end()
	}
	private func parse(tokens: [Token]) throws {
        variables.removeAll()
		constants.removeAll()
        morphs.removeAll()
		try parseTokens(tokens:tokens, start:0, stop:tokens.count)
	}

// Calculate =======================================================================================
	public func calculate() -> Obj? {

		if loadedKeys != nil { buildTokens(); loadedKeys = nil }
		do {
			try parse(tokens: self.tokens)
		} catch {
			return nil
		}

		guard variables.count == 0 else { return nil }

		let v: UnsafeMutablePointer<mnimi> = UnsafeMutablePointer<mnimi>.allocate(capacity: 0)

		let cn = constants.count
		let c: UnsafeMutablePointer<Obj> = UnsafeMutablePointer<Obj>.allocate(capacity: cn)
		for i in 0..<cn {
			c[i] = constants[i].obj
		}

		let mn = morphs.count
		let m: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: mn)
		for i in 0..<mn {
			m[i] = UInt8(morphs[i])
		}

		let lambda: UnsafeMutablePointer<Lambda> = AELambdaCreate(mnimi(0), c, UInt8(cn), v, UInt8(0), m, UInt8(mn), "".toInt8())

		v.deallocate()
		c.deallocate()
		m.deallocate()

		return AELambdaExecute(lambda, AEMemoryCreate(0))
	}

// Compiling =======================================================================================
	public func compile(name: String) -> UnsafeMutablePointer<Lambda>? {
		guard let tower = tower else { return nil }
		do {
			try parse(tokens: self.tokens)
			if tower.variableToken.status == .invalid {tower.variableToken.status = .ok}
			if let last = morphs.last {
				if let morph = Morph(rawValue: last) {
					tower.variableToken.def = morph.def
				} else {
					tower.variableToken.def = RealDef.def
				}
			}
		} catch {
			if tower.variableToken.status == .ok {tower.variableToken.status = .invalid}
			return nil
		}
		
		let memory = tower.memory
		
		let vi: mnimi = AEMemoryIndexForName(memory, name.toInt8())
		
		let vn = variables.count
		let v: UnsafeMutablePointer<mnimi> = UnsafeMutablePointer<mnimi>.allocate(capacity: vn)
		for i in 0..<vn {
			v[i] = AEMemoryIndexForName(memory, variables[i].toInt8())
		}
		
		let cn = constants.count
		let c: UnsafeMutablePointer<Obj> = UnsafeMutablePointer<Obj>.allocate(capacity: cn)
		for i in 0..<cn {
			c[i] = constants[i].obj
		}
		
		let mn = morphs.count
		let m: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: mn)
		for i in 0..<mn {
			m[i] = UInt8(morphs[i])
		}

		let lambda: UnsafeMutablePointer<Lambda> = AELambdaCreate(mnimi(vi), c, UInt8(cn), v, UInt8(vn), m, UInt8(mn), tokensDisplay.toInt8())
		
		v.deallocate()
		c.deallocate()
		m.deallocate()
		
		return lambda
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
	func buildWorker(tower: Tower) {
		let lambda: UnsafeMutablePointer<Lambda>? = compile(name: tower.name)
		tower.task = lambda != nil ? AETaskCreateLambda(lambda) : AETaskCreateNull()
        AETaskSetLabels(tower.task, tower.variableToken.tag.toInt8(), "\(tower.variableToken.alias ?? tower.variableToken.tag) = \(tokensDisplay)".toInt8())
	}
	func workerCompleted(tower: Tower, askedBy: Tower) -> Bool {
        AEMemoryLoaded(tower.memory, tower.index) != 0
    }
    func workerBlocked(tower: Tower) -> Bool {
        tokens.compactMap({ $0 as? TowerToken }).contains { $0.status != .ok }
    }
	func resetWorker(tower: Tower) {
        AEMemoryUnfix(tower.memory, tower.index)
    }
	func executeWorker(tower: Tower) {
		AETaskExecute(tower.task, tower.memory)
		AEMemoryFix(tower.memory, tower.index)
		tower.variableToken.def = tower.obje.def
	}

// CustomStringConvertible =========================================================================
    private var shouldDisplayTokens: Bool { editing || tower?.web != nil || tower?.variableToken.status != .ok || alwaysShow }
	override public var description: String {
		guard tokens.count > 0 else { return "" }
        guard shouldDisplayTokens else { return tower.obje.display }
		
        var sb = String()
        tokens.forEach { sb.append("\($0.display)") }
        return sb
	}
}

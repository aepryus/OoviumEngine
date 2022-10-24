//
//  Aether.swift
//  Oovium
//
//  Created by Joe Charlier on 12/30/16.
//  Copyright © 2016 Aepryus Software. All rights reserved.
//

import Aegean
import Acheron
import Foundation

@objc public final class Aether: Domain {
	@objc dynamic public var name: String = ""
	@objc dynamic public var width: Double = 0
	@objc dynamic public var height: Double = 0
	@objc dynamic public var xOffset: Double = 0
	@objc dynamic public var yOffset: Double = 0
	@objc dynamic public var readOnly: Bool = false
	@objc dynamic public var version: String = ""

	@objc dynamic public var aexels: [Aexel] = []
	
	private var nos: IntMap = IntMap()
	private var tokens: [String:TowerToken] = [:]
	private var towers: [TowerToken:Tower] = [:]
	public private(set) var memory: UnsafeMutablePointer<Memory> = AEMemoryCreate(0)

	public override init() { super.init() }
	public required init(attributes: [String:Any], parent: Domain? = nil) { super.init(attributes: attributes, parent: parent) }
	public init(json: String) {
		let attributes: [String:Any] = json.toAttributes()
		super.init(attributes: attributes)
		load(attributes: attributes)
	}

	deinit { AEMemoryRelease(memory) }

// Evaluate ========================================================================================
	public func buildMemory() {
		var vars: [String] = ["k"]
		vars += tokens.values.filter { $0 is VariableToken }.map { $0.tag }
		vars.sort(by: { $0.uppercased() < $1.uppercased() })

		let oldMemory: UnsafeMutablePointer<Memory> = memory
		memory = AEMemoryCreate(vars.count)
		vars.enumerated().forEach { AEMemorySetName(memory, UInt16($0), $1.toInt8()) }
		AEMemoryLoad(memory, oldMemory)
		AEMemoryRelease(oldMemory)

		Set(towers.values).filter { $0.variableToken.type == .variable }.forEach { $0.buildTask() }
	}
	public func prepare() {
		var towers = Set<Tower>()
		aexels.forEach { towers.formUnion($0.towers) }
		towers.forEach { register(tower: $0) }
		towers.forEach { $0.buildStream() }
		buildMemory()
	}
    public func evaluate() { Tower.evaluate(towers: Set(towers.values)) }

// Aexels ==========================================================================================
	private func addAexel(_ aexel: Aexel) {
		add(aexel)
		aexels.append(aexel)
		aexel.towers.forEach { register(tower: $0) }
		aexel.towers.forEach { $0.buildStream() }
		buildMemory()
        Tower.evaluate(towers: aexel.towers)
	}
	public func removeAexel(_ aexel: Aexel) {
		aexel.towers.forEach { deregister(tower: $0) }
		remove(aexel)
		aexels.remove(object: aexel)
	}
	public func removeAexels(_ aexels: [Aexel]) {
		aexels.forEach { $0.towers.forEach { deregister(tower: $0) } }
		aexels.forEach { remove($0) }
		aexels.forEach { self.aexels.remove(object: $0) }
		buildMemory()
	}
	public func removeAllAexels() { removeAexels(aexels) }
    
    public func create<T: Aexel>(at: V2) -> T {
        let key: String = "\(T.self)".lowercased()
        print("QQ: [\(key)]")
        let aexel = T(no: nos.increment(key: key), at: at, aether: self)
        addAexel(aexel)
        return aexel
    }
	
	public func first<T>() -> T? { aexels.first(where: {$0 is T}) as? T }
    public func aexel<T>(no: Int) -> T? { aexels.first(where: { $0 is T  && $0.no == no }) as? T }

	// Text
	public func createEdge(parent: Text, child: Text) -> Edge {
		let edge = Edge(parent: parent)
		edge.textNo = child.no
		return edge
	}
	public func outputEdges(for text: Text) -> [Edge] {
		var edges: [Edge] = []
		aexels.forEach {
			guard let other = $0 as? Text, let edge = other.edgeFor(text: text) else { return }
			edges.append(edge)
		}
		return edges
	}
	
// Tokens ==========================================================================================
	public func register(token: TowerToken) { tokens[token.key] = token }
	public func token(type: TokenType, tag: String) -> TowerToken? { tokens["\(type.rawValue):\(tag)"] }
	public func token(key: String) -> Token {
		var token: Token? = tokens[key]
		if let token = token { return token }
		token = Token.token(key: key)
		if let token = token { return token }

		let subs: [Substring] = key.split(separator: ":")
		let s0: Int = Int(String(subs[0]))!
		let s1: String = String(subs[1])
		let type: TokenType = TokenType(rawValue: s0)!
		let tag: String = Token.aliases[s1] ?? s1

		switch type {
			case .variable: token = variableToken(tag: tag)
			case .function: token = functionToken(tag: tag)
			default:
				token = functionToken(tag: tag) // fatalError()
		}
		tokens[key] = token as? TowerToken
		return token!
	}
	public func buildTokens(chain: Chain) {
		guard let keys = chain.loadedKeys else { return }
        chain.tokens = keys.map { token(key: $0) }
		chain.loadedKeys = nil
	}
	public func buildTokens() {
		aexels.forEach { $0.towers.forEach {
			guard let chain = $0.delegate as? Chain else { return }
			buildTokens(chain: chain)
		}}
        (aexels.filter { $0 is Grid } as! [Grid]).forEach { $0.columns.forEach {
            buildTokens(chain: $0.chain)
        }}
	}

	public func rekey(token: TowerToken, tag:String) {
		tokens[token.key] = nil
		token.tag = tag
		tokens[token.key] = token
	}

	public func variableToken(tag: String, label: String? = nil) -> VariableToken {
		return tokens["\(TokenType.variable.rawValue):\(tag)"] as? VariableToken ?? {
			let token = VariableToken(tag: tag, label: label)
			register(token: token)
			return token
		}()
	}
	public func functionToken(tag: String, label: String? = nil, recipe: String? = nil) -> FunctionToken {
		return tokens["\(TokenType.function.rawValue):\(tag)"] as? FunctionToken ?? {
			let token = FunctionToken(tag: tag, label: label, recipe: recipe)
			register(token: token)
			return token
		}()
	}
	public func wipe(token: Token) { tokens[token.key] = nil }

// Towers ==========================================================================================
	func register(tower: Tower) {
		towers[tower.variableToken] = tower
		if let functionToken = tower.functionToken { towers[functionToken] = tower }
	}
	func deregister(tower: Tower) {
		towers[tower.variableToken] = nil
		if let functionToken = tower.functionToken { towers[functionToken] = nil }
	}
    func tower(towerToken: TowerToken) -> Tower? { towers[towerToken] }
    
    public func delete(towers: Set<Tower>) {
        var affected: Set<Tower> = Set<Tower>()
        towers.forEach { affected.formUnion($0.allDownstream()) }
        affected.subtract(towers)
        
        towers.forEach {
            $0.variableToken.status = .deleted
            $0.variableToken.label = "DELETED"
            if $0.variableToken.type == .variable { AEMemoryUnfix(memory, $0.index) }
            $0.abstract()
        }
        
        Tower.evaluate(towers: affected)
    }

// Functions =======================================================================================
	public func functionExists(name: String) -> Bool { aexels.first { $0 is Mechlike && $0.name == name } != nil }

// MARK: - Events ==================================================================================
	override public func onLoad() {
		aexels.forEach {
			guard $0.no > nos.get(key: $0.type) else { return }
			nos.set(key: $0.type, to: $0.no)
		}
		buildTokens()
		prepare()
		evaluate()
	}
	
// MARK: - Domain ==================================================================================
    override public var properties: [String] { super.properties + ["name", "width", "height", "xOffset", "yOffset", "readOnly", "version"] }
    override public var children: [String] { super.children + ["aexels"] }

// MARK: - Static ==================================================================================
	public static var engineVersion: String { "3.0" }
}

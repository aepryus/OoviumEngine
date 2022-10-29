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

		Set(towers.values).filter { $0.variableToken.code == .va }.forEach { $0.buildTask() }
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
		aexels.remove(object: aexel)
        remove(aexel)
	}
	public func removeAllAexels() {
        aexels.forEach { removeAexel($0) }
        buildMemory()
    }
    
    public func create<T: Aexel>(at: V2) -> T {
        let key: String = "\(T.self)".lowercased()
        let aexel: T = T(no: nos.increment(key: key), at: at, aether: self)
        addAexel(aexel)
        return aexel
    }
	
    public func first<T: Aexel>() -> T? { aexels.first(where: {$0 is T}) as? T }
    public func aexel<T: Aexel>(no: Int) -> T? { aexels.first(where: { $0 is T  && $0.no == no }) as? T }

	// Text
    public func createEdge(parent: Text, child: Text) -> Edge { Edge(parent: parent, child: child) }
	public func outputEdges(for text: Text) -> [Edge] { aexels.compactMap { ($0 as? Text)?.edgeFor(text: text) } }
	
// Towers ==========================================================================================
    func register(tower: Tower) {
        towers[tower.variableToken] = tower
        if let mechlikeToken = tower.mechlikeToken { towers[mechlikeToken] = tower }
    }
    func deregister(tower: Tower) {
        towers[tower.variableToken] = nil
        if let mechlikeToken = tower.mechlikeToken { towers[mechlikeToken] = nil }
    }
    
    public func delete(towers: Set<Tower>) {
        var affected: Set<Tower> = Set<Tower>()
        towers.forEach { affected.formUnion($0.allDownstream()) }
        affected.subtract(towers)
        
        towers.forEach {
            $0.variableToken.status = .deleted
//            $0.variableToken.label = "DELETED"
            if $0.variableToken.code == .va { AEMemoryUnfix(memory, $0.index) }
            $0.abstract()
        }
        
        Tower.evaluate(towers: affected)
    }
    func createTower(tag: String, towerDelegate: TowerDelegate, tokenDelegate: VariableTokenDelegate? = nil) -> Tower {
        let token = VariableToken(tag: tag, delegate: tokenDelegate)
        tokens[token.key] = token
        return Tower(aether: self, token: token, delegate: towerDelegate)
    }
    func destroyTower(_ tower: Tower) {
    }

// Tokens ==========================================================================================
    public func mechlikeToken(tower: Tower? = nil, tag: String, label: String? = nil, recipe: String? = nil) -> MechlikeToken {
        return tokens["\(Token.Code.ml):\(tag)"] as? MechlikeToken ?? {
            let token = MechlikeToken(tower: tower, tag: tag, label: label, recipe: recipe)
            tokens[token.key] = token
			return token
		}()
	}

// Functions =======================================================================================
	public func functionExists(name: String) -> Bool { aexels.first { $0 is Mechlike && $0.name == name } != nil }

// Events ==========================================================================================
	override public func onLoad() {
        func buildTokens(chain: Chain) {
            func token(key: String) -> Token {
                if let token: Token = tokens[key] ?? Token.token(key: key) { return token }
                return Token.zero
            }

            chain.tokens = chain.loadedKeys?.map({ token(key: $0) }) ?? []
            chain.loadedKeys = nil
        }

		aexels.forEach {
			guard $0.no > nos.get(key: $0.type) else { return }
			nos.set(key: $0.type, to: $0.no)
		}
        
        aexels.flatMap({ $0.towers }).compactMap({ $0.delegate as? Chain }).forEach { buildTokens(chain: $0) }
        aexels.compactMap({ $0 as? Grid }).flatMap({ $0.columns }).forEach { buildTokens(chain: $0.chain) }

        prepare()
		evaluate()
        
        AEMemoryPrint(memory)
	}
	
// Domain ==========================================================================================
    override public var properties: [String] { super.properties + ["name", "width", "height", "xOffset", "yOffset", "readOnly", "version"] }
    override public var children: [String] { super.children + ["aexels"] }

// Static ==========================================================================================
	public static var engineVersion: String { "3.0" }
}

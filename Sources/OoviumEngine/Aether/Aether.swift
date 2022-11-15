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
        vars += tokens.values.filter { $0.code == .va && $0.status != .deleted }.map { $0.tag }
		vars.sort(by: { $0.uppercased() < $1.uppercased() })

		let oldMemory: UnsafeMutablePointer<Memory> = memory
		memory = AEMemoryCreate(vars.count)
		vars.enumerated().forEach { AEMemorySetName(memory, UInt16($0), $1.toInt8()) }
		AEMemoryLoad(memory, oldMemory)
		AEMemoryRelease(oldMemory)
	}
    public func evaluate() { Tower.evaluate(towers: Set(towers.values)) }

// Aexels ==========================================================================================
	public func addAexel(_ aexel: Aexel) {
		add(aexel)
		aexels.append(aexel)

        aexel.towers.forEach { $0.buildStream() }
		buildMemory()
        Tower.evaluate(towers: aexel.towers)
	}
    public func remove(aexels: [Aexel]) {
        var removed: [Tower] = []
        aexels.forEach({
            removed.append(contentsOf: $0.towers)
            self.aexels.remove(object: $0)
            remove($0)
        })
        destroy(towers: removed)
    }
	public func remove(aexel: Aexel) { remove(aexels: [aexel]) }
	public func removeAllAexels() { remove(aexels: aexels) }
    
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
    public func destroy(towers: [Tower]) {
        var affected: Set<Tower> = Set<Tower>()
        towers.forEach { affected.formUnion($0.allDownstream()) }
        affected.subtract(towers)
        
        towers.forEach { (tower: Tower) in
            tower.variableToken.status = .deleted
            tower.abstract()
            self.towers[tower.variableToken] = nil
            self.tokens[tower.variableToken.key] = nil
            if let mechlikeToken = tower.mechlikeToken {
                self.towers[mechlikeToken] = nil
                self.tokens[mechlikeToken.key] = nil
            }
        }
        
        Tower.evaluate(towers: affected)
        buildMemory()
    }
    public func destroy(tower: Tower) { destroy(towers: [tower]) }
    func createTower(tag: String, towerDelegate: TowerDelegate, tokenDelegate: VariableTokenDelegate? = nil) -> Tower {
        let token = VariableToken(tag: tag, delegate: tokenDelegate)
        tokens[token.key] = token
        let tower = Tower(aether: self, token: token, delegate: towerDelegate)
        towers[token] = tower
        return tower
    }
    func createMechlikeTower(tag: String, towerDelegate: TowerDelegate, tokenDelegate: VariableTokenDelegate? = nil) -> Tower {
        let variableToken = VariableToken(tag: tag, delegate: tokenDelegate)
        tokens[variableToken.key] = variableToken
        let tower = Tower(aether: self, token: variableToken, delegate: towerDelegate)
        let mechlikeToken = MechlikeToken(tower: tower, tag: tag, delegate: tokenDelegate)
        tokens[mechlikeToken.key] = mechlikeToken
        tower.mechlikeToken = mechlikeToken
        towers[variableToken] = tower
        towers[mechlikeToken] = tower
        return tower
    }
    public func mechlikeToken(tag: String) -> MechlikeToken? { tokens["\(Token.Code.ml):\(tag)"] as? MechlikeToken }
    func createColumnTower(tag: String, towerDelegate: TowerDelegate, tokenDelegate: VariableTokenDelegate? = nil) -> Tower {
        let token = ColumnToken(tag: tag, delegate: tokenDelegate)
        tokens[token.key] = token
        let tower = Tower(aether: self, token: token, delegate: towerDelegate)
        towers[token] = tower
        return tower
    }
    
// Functions =======================================================================================
	public func functionExists(name: String) -> Bool { aexels.first { $0 is Mechlike && $0.name == name } != nil }

// Events ==========================================================================================
	override public func onLoad() {
        func buildTokens(chain: Chain) {
            guard chain.loadedKeys != nil else { return }
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
        aexels.flatMap({ $0.towers }).forEach { $0.buildStream() }
        buildMemory()
        evaluate()
	}
	
// Domain ==========================================================================================
    override public var properties: [String] { super.properties + ["name", "width", "height", "xOffset", "yOffset", "readOnly", "version"] }
    override public var children: [String] { super.children + ["aexels"] }

// Static ==========================================================================================
	public static var engineVersion: String { "3.0" }
}

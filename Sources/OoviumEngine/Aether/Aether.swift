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
    
//    public var state: AetherExe!

	public override init() { super.init() }
	public required init(attributes: [String:Any], parent: Domain? = nil) { super.init(attributes: attributes, parent: parent) }
	public init(json: String) {
		let attributes: [String:Any] = json.toAttributes()
		super.init(attributes: attributes)
		load(attributes: attributes)
	}

    
//    func token(key: String) -> Token? { state.token(key: key) }
//    func variableToken(tag: String) -> Token { state.variableToken(tag: tag) }
    func newNo(type: String) -> Int { (aexels.filter({ $0.type == type }).map({ $0.no }).max() ?? 0) + 1 }
    
    func compile() -> AetherExe { AetherExe(aether: self) }

// Aexels ==========================================================================================
	public func addAexel(_ aexel: Aexel) {
		add(aexel)
		aexels.append(aexel)

//        aexel.towers.forEach { $0.buildStream() }
//        state.buildMemory()
//        Tower.evaluate(towers: aexel.towers)
	}
    public func remove(aexels: [Aexel]) {
//        let removed: [Tower] = []
        aexels.forEach({
//            removed.append(contentsOf: $0.towers)
            self.aexels.remove(object: $0)
            remove($0)
        })
//        state.destroy(towers: removed)
    }
	public func remove(aexel: Aexel) { remove(aexels: [aexel]) }
	public func removeAllAexels() { remove(aexels: aexels) }
    
    public func create<T: Aexel>(at: V2) -> T {
        let aexel: T = T(at: at, aether: self)
//        aexel.chains.forEach { self.state.add(chain: $0) }
        addAexel(aexel)
        return aexel
    }
	
    public func first<T: Aexel>() -> T? { aexels.first(where: {$0 is T}) as? T }
    public func aexel<T: Aexel>(no: Int) -> T? { aexels.first(where: { $0 is T  && $0.no == no }) as? T }

	// Text
    public func createEdge(parent: Text, child: Text) -> Edge { Edge(parent: parent, child: child) }
	public func outputEdges(for text: Text) -> [Edge] { aexels.compactMap { ($0 as? Text)?.edgeFor(text: text) } }
	
// Chains ==========================================================================================
    func inject(chain: Chain, tag: String) {
//        chain.tower = state.createTower(tag: tag, towerDelegate: chain)
    }
    
// Functions =======================================================================================
	public func functionExists(name: String) -> Bool { aexels.first { $0 is Mechlike && $0.name == name } != nil }

// Events ==========================================================================================
//    override public func onLoad() {
//        state = AetherExe(aether: self)
//        state.evaluate()
//        print(unload().toJSON())
//    }
	
// Domain ==========================================================================================
    override public var properties: [String] { super.properties + ["name", "width", "height", "xOffset", "yOffset", "readOnly", "version"] }
    override public var children: [String] { super.children + ["aexels"] }

// Static ==========================================================================================
	public static var engineVersion: String { "3.1" }
}

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

@objc public class Aether: Domain {
	@objc dynamic public var name: String = ""
	@objc dynamic public var width: Double = 0
	@objc dynamic public var height: Double = 0
	@objc dynamic public var xOffset: Double = 0
	@objc dynamic public var yOffset: Double = 0
	@objc dynamic public var readOnly: Bool = false
	@objc dynamic public var version: String = ""

	@objc dynamic public var aexels: [Aexel] = []
    
	public override init() { super.init() }
	public required init(attributes: [String:Any], parent: Domain? = nil) { super.init(attributes: attributes, parent: parent) }
	public init(json: String) {
		let attributes: [String:Any] = json.toAttributes()
		super.init(attributes: attributes)
		load(attributes: attributes)
	}
    
    var chains: [Chain] { aexels.flatMap({ $0.chains }) }
    
    func newNo(type: String) -> Int { (aexels.filter({ $0.type == type }).map({ $0.no }).max() ?? 0) + 1 }
    
    public func compile() -> Citadel { Citadel(aether: self) }
    
    func rekey(subs: [TokenKey:TokenKey?]) {
        chains.forEach { (chain: Chain) in
            chain.key = subs[chain.key!] ?? chain.key
            chain.tokenKeys = chain.tokenKeys.map({ (tokenKey: TokenKey) in
                if let subNil: TokenKey? = subs[tokenKey] {
                    if let sub: TokenKey = subNil {
                        return sub
                    } else {
                        fatalError()
                    }
                } else {
                    return tokenKey
                }
            })
        }
    }

// Aexels ==========================================================================================
	public func addAexel(_ aexel: Aexel) {
		add(aexel)
		aexels.append(aexel)
	}
    public func remove(aexels: [Aexel]) {
        aexels.forEach({
            self.aexels.remove(object: $0)
            remove($0)
        })
    }
	public func remove(aexel: Aexel) { remove(aexels: [aexel]) }
	public func removeAllAexels() { remove(aexels: aexels) }
    
    public func create<T: Aexel>(at: V2) -> T {
        let aexel: T = T(at: at, aether: self)
        addAexel(aexel)
        return aexel
    }
	
    public func first<T: Aexel>() -> T? { aexels.first(where: {$0 is T}) as? T }
    public func aexel<T: Aexel>(no: Int) -> T? { aexels.first(where: { $0 is T  && $0.no == no }) as? T }

	// Text
    public func createEdge(parent: Text, child: Text) -> Edge { Edge(parent: parent, child: child) }
	public func outputEdges(for text: Text) -> [Edge] { aexels.compactMap { ($0 as? Text)?.edgeFor(text: text) } }
	
// Functions =======================================================================================
	public func functionExists(name: String) -> Bool { aexels.first { $0 is Mechlike && $0.name == name } != nil }

// Domain ==========================================================================================
    public override var properties: [String] { super.properties + ["name", "width", "height", "xOffset", "yOffset", "readOnly", "version"] }
    public override var children: [String] { super.children + ["aexels"] }

// Static ==========================================================================================
    static func ensureUniquiness(name: String, names: [String]) -> String {
        var newName: String = name
        var i: Int = 2
        while names.contains(newName) { newName = "\(name)\(i)"; i += 1 }
        return newName
    }
    
	public static var engineVersion: String { "3.1" }
}

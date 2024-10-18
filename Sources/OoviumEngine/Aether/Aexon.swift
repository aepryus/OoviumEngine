//
//  Aexon.swift
//  OoviumEndine
//
//  Created by Joe Charlier on 7/6/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import Acheron
import Foundation

public class Aexon: Domain {
    @objc public var no: Int = 0
    
// Inits ===========================================================================================
    public override init(parent: Domain) {
        let typeName: String = String(describing: Self.self).lowercased()
        
        if let aether: Aether = parent as? Aether {
            self.no = aether.newNo(type: typeName)
        }
        else { self.no = (parent as! Aexon).newNo(type: typeName) }
        super.init(parent: parent)
    }
    public required init(attributes: [String:Any], parent: Domain?) {
        super.init(attributes: attributes, parent: parent)
        load(attributes: attributes)
    }
    
// Computed ========================================================================================
    public var aexel: Aexel { (parent as! Aexon).aexel }
    public var aether: Aether { (parent as! Aexon).aether }

    var code: String { fatalError() }
    var key: String { "\(code)\(no)" }
    var fullKey: String { "\((parent as! Aexon).fullKey).\(key)" }
    public var tokenKeys: [TokenKey] { [] }

// Methods =========================================================================================
    func newNo(type: String) -> Int { aether.newNo(type: type) }
    func createCores() -> [Core] { [] }
    
// Domain ==========================================================================================
    override open var properties: [String] { super.properties + ["no"] }
}

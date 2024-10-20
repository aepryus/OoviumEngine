//
//  Cell.swift
//  Oovium
//
//  Created by Joe Charlier on 12/30/16.
//  Copyright © 2016 Aepryus Software. All rights reserved.
//

import Acheron
import Foundation

public class Cell: Aexon {
	@objc public var chain: Chain!

// Inits ===========================================================================================
	public required init(column: Column) {
        super.init(parent: column)
        chain = Chain(key: TokenKey(code: .va, tag: fullKey))
	}
	public required init(attributes: [String:Any], parent: Domain?) {
		super.init(attributes: attributes, parent: parent)
	}
    
// Computed ========================================================================================
    public var column: Column { parent as! Column }
    public var grid: Grid { column.grid }
    
    public var colNo: Int { column.colNo }
    public var rowNo: Int { column.rowNo(for: self) }

// Aexon ===========================================================================================
    override var code: String { "Ce" }
    public override var tokenKeys: [TokenKey] { [ chain.key! ] }
    override func createCores() -> [Core] { [
        ChainCore(chain: chain)
    ] }

// Domain ==========================================================================================
    public override var properties: [String] { super.properties + ["chain"] }
}
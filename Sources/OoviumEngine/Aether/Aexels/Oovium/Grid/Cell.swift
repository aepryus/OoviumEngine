//
//  Cell.swift
//  Oovium
//
//  Created by Joe Charlier on 12/30/16.
//  Copyright © 2016 Aepryus Software. All rights reserved.
//

import Acheron
import Foundation

public final class Cell: Aexon {
	@objc public var colNo: Int = 0
	@objc public var rowNo: Int = 0
	@objc public var chain: Chain!

// Inits ===========================================================================================
	public required init(grid: Grid) {
        super.init(parent: grid)
        chain = Chain(key: TokenKey(code: .va, tag: key))
	}
	public required init(attributes: [String:Any], parent: Domain?) {
		super.init(attributes: attributes, parent: parent)
	}
    
// Computed ========================================================================================
//    public var tower: Tower { chain.tower }
//    public var token: Token { tower.variableToken }
    
    public var grid: Grid { parent as! Grid }
    public var column: Column { grid.columns[colNo] }
    
// Events ==========================================================================================
	public override func onLoad() {
//        chain.tower = grid.aether.state.createTower(tag: fullKey, towerDelegate: chain)
	}
    
// Aexon ===========================================================================================
    override var code: String { "Ce" }

// Domain ==========================================================================================
	override public var properties: [String] { super.properties + ["colNo", "rowNo", "chain"] }
}

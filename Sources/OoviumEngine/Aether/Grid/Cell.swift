//
//  Cell.swift
//  Oovium
//
//  Created by Joe Charlier on 12/30/16.
//  Copyright © 2016 Aepryus Software. All rights reserved.
//

import Acheron
import Foundation

public final class Cell: Domain {
	@objc public var no: Int = 0
	@objc public var colNo: Int = 0
	@objc public var rowNo: Int = 0
	@objc public var chain: Chain!

	public var _width: Double? = nil
    
    var key: String { "Ce\(no)" }

	public var tower: Tower { chain.tower }
	public var token: Token { tower.variableToken }
	
    public var grid: Grid { parent as! Grid }
	public var column: Column { grid.columns[colNo] }
	
// Inits ===========================================================================================
	public required init(grid: Grid) {
		chain = Chain()
		no = grid.maxCellNo + 1

		super.init()
		
		parent = grid
		chain.tower = grid.aether.createTower(tag: "\(grid.key).\(key)", towerDelegate: chain)
	}
	public required init(attributes: [String:Any], parent: Domain?) {
		super.init(attributes: attributes, parent: parent)
	}
	
// Events ==========================================================================================
	public override func onLoad() {
        chain.tower = grid.aether.createTower(tag: "\(grid.key).\(key)", towerDelegate: chain)
	}

// Domain ==========================================================================================
	override public var properties: [String] {
		return super.properties + ["no", "colNo", "rowNo", "chain"]
	}
}

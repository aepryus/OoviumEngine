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
	@objc var colNo: Int = 0
	@objc var rowNo: Int = 0
	@objc var chain: Chain!
	
//	var _width: CGFloat? = nil
//	var width: CGFloat {
//		get {
//			if _width == nil { renderWidth() }
//			return _width!
//		}
//	}

	var tower: Tower {
		return chain.tower
	}
	var token: Token {
		return tower.variableToken
	}
	
	var grid: Grid {
		return parent as! Grid
	}
	var column: Column {
		return grid.columns[colNo]
	}
	
//	func renderWidth() {
//		_width = ChainView.calcWidth(chain: chain)+6
//	}

// Inits ===========================================================================================
	public required init(grid: Grid) {
		chain = Chain()
		no = grid.maxCellNo + 1

		super.init()
		
		parent = grid
		chain.tower = Tower(aether: grid.aether, token: grid.aether.variableToken(tag: "Gr\(grid.no).Ce\(no)"), delegate: chain)
	}
	public required init(attributes: [String:Any], parent: Domain?) {
		super.init(attributes: attributes, parent: parent)
	}
	
// Events ==========================================================================================
	public override func onLoad() {
		chain.tower = Tower(aether: grid.aether, token: grid.aether.variableToken(tag: "Gr\(grid.no).Ce\(no)"), delegate: chain)
	}

// Domain ==========================================================================================
	override public var properties: [String] {
		return super.properties + ["no", "colNo", "rowNo", "chain"]
	}
}

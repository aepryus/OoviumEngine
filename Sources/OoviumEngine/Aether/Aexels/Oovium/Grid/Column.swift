//
//  Col.swift
//  Oovium
//
//  Created by Joe Charlier on 12/30/16.
//  Copyright © 2016 Aepryus Software. All rights reserved.
//

import Aegean
import Acheron
import Foundation

@objc public enum OOAggregate: Int {
	case none, sum, average, running, count, match
}
@objc public enum OOJustify: Int {
	case left, center, right
}

public class Column: Aexon {
//	@objc public var no: Int = 0
	@objc public var name: String = ""
	var def: Def = RealDef.def
	@objc public var chain: Chain!
	@objc public var aggregate: OOAggregate = .none
	@objc public var justify: OOJustify = .right
	@objc public var format: String = ""

	public var _width: Double? = nil
	public var _headerWidth: Double? = nil
	public var _footerWidth: Double? = nil
    
    public lazy var headerTokenKey: TokenKey = TokenKey(code: .cl, tag: fullKey)
    public lazy var footerTokenKey: TokenKey = TokenKey(code: .va, tag: fullKey)
    
    public lazy var footerChain: Chain = Chain(key: footerTokenKey)
	
	public var grid: Grid { parent as! Grid }
    public var calculated: Bool { !chain.isEmpty }
	public var hasFooter: Bool { aggregate != .none && aggregate != .running }
    public var colNo: Int { grid.columns.enumerated().first(where: { $0.1 === self })!.0 }
    public var cells: [Cell] { grid.cellsForColumn(colNo: no) }
	
	public func render() {
//		if aggregate != .none {
//            grid.aether.state.buildMemory()
//            footerChain.tower.buildStream()
//            grid.aether.state.evaluate()
//		}
	}
    
    public func disseminate() {
        guard !chain.isEmpty else { return }
        
        if aggregate != .running {
            for i in 0..<grid.rows {
                let cell = grid.cell(colNo: colNo, rowNo: i)
                cell.chain.clear()

                for tokenKey: TokenKey in chain.tokenKeys {
                    if let column = grid.column(tag: tokenKey.tag) {
                        let other: Cell = grid.cell(colNo: column.colNo, rowNo: i)
                        cell.chain.post(key: other.chain.key!)
                    } else {
                        cell.chain.post(key: tokenKey)
                    }
                }
            }
            if aggregate == .match {
                footerChain.clear()
                for token in chain.tokenKeys {
                    if let column = grid.column(tag: token.tag) {
                        column.footerChain.post(key: column.footerChain.key!)
                    } else {
                        footerChain.post(key: token)
                    }
                }
            }

        } else {
            for i in 0..<grid.rows {
                let cell = grid.cell(colNo: colNo, rowNo: i)
                cell.chain.clear()

                for tokenKey: TokenKey in chain.tokenKeys {
                    if let column = grid.column(tag: tokenKey.tag) {
                        let other: Cell = grid.cell(colNo: column.colNo, rowNo: i)
                        cell.chain.post(key: other.chain.key!)
                    } else {
                        cell.chain.post(key: tokenKey)
                    }
                }
                if i != 0 {
                    cell.chain.post(key: Token.add.key)
                    let above: Cell = grid.cell(colNo: colNo, rowNo: i-1)
                    cell.chain.post(key: above.chain.key!)
                }
            }
        }
    }
    public func cellKeys() -> [TokenKey] { grid.cells.filter({ $0.colNo == colNo }).map({ $0.chain.key! }) }

// Inits ===========================================================================================
	public init(grid: Grid) {
//		no = grid.maxColumnNo + 1
        super.init(parent: grid)
		parent = grid
        chain = Chain(key: headerTokenKey)
//        footerChain = Chain(key: TokenKey(code: .va, tag: fullKey))
//		chain.tower = tower
//		chain.alwaysShow = true
//		footerChain.tower = footerTower
	}
	public required init(attributes: [String:Any], parent: Domain?) {
		super.init(attributes: attributes, parent: parent)
	}
	
// Aexon ===========================================================================================
    override var code: String { "Co" }
    public override var tokenKeys: [TokenKey] {
        cells.flatMap({ $0.tokenKeys }) + [
            headerTokenKey,
            footerTokenKey
        ]
    }
    override func createCores() -> [Core] {
        cells.flatMap({ $0.createCores() }) + [
            HeaderCore(column: self),
            FooterCore(column: self)
        ]
    }
    
// Domain ==========================================================================================
    public override var properties: [String] { super.properties + ["name", "chain", "aggregate", "justify", "format"] }
}

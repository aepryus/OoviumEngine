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

//	public var footerChain: Chain!
    
//    public lazy var tokenKey: TokenKey = TokenKey(code: .cl, tag: fullKey)
	
	fileprivate lazy var header: Header = Header()
    
//    public lazy var tower: Tower = grid.aether.state.createColumnTower(tag: "\(grid.key).Co\(no)", towerDelegate: header, tokenDelegate: self)
//    public lazy var footerTower: Tower = grid.aether.state.createTower(tag: "\(grid.key).Ft\(no)", towerDelegate: self)
    
    public lazy var footerTokenKey: TokenKey = TokenKey(code: .va, tag: fullKey)
	
	public var grid: Grid { parent as! Grid }
    public var calculated: Bool { !chain.isEmpty }
	public var hasFooter: Bool { aggregate != .none && aggregate != .running }
    public var colNo: Int { grid.columns.enumerated().first(where: { $0.1 === self })!.0 }
	
	public func render() {
//		if aggregate != .none {
//            grid.aether.state.buildMemory()
//            footerChain.tower.buildStream()
//            grid.aether.state.evaluate()
//		}
	}

// Inits ===========================================================================================
	public init(grid: Grid) {
//		no = grid.maxColumnNo + 1
        super.init(parent: grid)
		parent = grid
        chain = Chain(key: TokenKey(code: .cl, tag: fullKey))
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
    public override var tokenKeys: [TokenKey] { [
        chain.key!,
        footerTokenKey
    ] }
    override func createCores() -> [Core] { [
        ChainCore(chain: chain),
        ColumnCore(column: self)
    ] }
    
// Domain ==========================================================================================
    public override var properties: [String] { super.properties + ["name", "chain", "aggregate", "justify", "format"] }
}

fileprivate class Header: Core {
    override func buildUpstream(tower: Tower) {}
    override func renderDisplay(tower: Tower) -> String { "---" }
    override func renderTask(tower: Tower) -> UnsafeMutablePointer<Task>? { nil }
    override func taskCompleted(tower: Tower, askedBy: Tower) -> Bool { true }
    override func resetTask(tower: Tower) {}
    override func executeTask(tower: Tower) {}
}

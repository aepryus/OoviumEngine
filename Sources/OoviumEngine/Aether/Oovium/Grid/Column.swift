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


public class Column: Aexon, VariableTokenDelegate {
    @objc public enum Aggregate: Int { case none, sum, average, running, count, match }
    @objc public enum Justify: Int { case left, center, right }

    @objc public var name: String = ""
	var def: Def = RealDef.def
	@objc public var chain: Chain!
	@objc public var aggregate: Aggregate = .none
	@objc public var justify: Justify = .right
	@objc public var format: String = ""
    @objc public lazy var footerChain: Chain = Chain(key: footerTokenKey)
    
    @objc public var cells: [Cell] = []

	public var _width: Double? = nil
	public var _headerWidth: Double? = nil
	public var _footerWidth: Double? = nil
    
    public var headerTokenKey: TokenKey { TokenKey(code: .cl, tag: fullKey) }
    public var footerTokenKey: TokenKey { TokenKey(code: .va, tag: "\(grid.key).Ft\(colNo)") }
    
	public var grid: Grid { parent as! Grid }
    public var calculated: Bool = false
	public var hasFooter: Bool { aggregate != .none && aggregate != .running }
    public var colNo: Int { (grid.columns.firstIndex(of: self) ?? grid.columns.count) + 1 }
	
// Inits ===========================================================================================
	public init(grid: Grid) {
        super.init(parent: grid)
        name = Grid.name(n: no)
        chain = Chain(key: headerTokenKey)

        for _ in 0..<grid.rows { cells.append(Cell(column: self)) }
	}
	public required init(attributes: [String:Any], parent: Domain?) {
		super.init(attributes: attributes, parent: parent)
	}
    
    public var maxCellNo: Int { cells.maximum({ $0.no }) ?? 0 }
    public func cell(rowNo: Int) -> Cell { cells[rowNo-1] }

    public func disseminate() {
        guard !chain.isEmpty || calculated else { return }
        
        if aggregate != .running {
            for i in 1...grid.rows {
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
                        footerChain.post(key: column.footerTokenKey)
                    } else {
                        footerChain.post(key: token)
                    }
                }
            }

        } else {
            for i in 1...grid.rows {
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
                if i != 1 {
                    cell.chain.post(key: Token.add.key)
                    let above: Cell = grid.cell(colNo: colNo, rowNo: i-1)
                    cell.chain.post(key: above.chain.key!)
                }
            }
        }
        calculated = !chain.isEmpty
    }
    public func cellKeys() -> [TokenKey] { cells.map({ $0.chain.key! }) }
    
    func rowNo(for cell: Cell) -> Int { (cells.firstIndex(of: cell) ?? cells.count) + 1 }
    func addRow() -> Cell {
        let cell: Cell = Cell(column: self)
        cells.append(cell)
        return cell
    }
    public func move(rowNo: Int, toRowNo: Int) {
        let cell: Cell = cells.remove(at: rowNo-1)
        cells.insert(cell, at: toRowNo-1)
    }
    func delete(rowNo: Int) { cells.remove(at: rowNo-1) }
    
// Events ==========================================================================================
    public override func onLoad() {
        calculated = !chain.isEmpty
    }

// Aexon ===========================================================================================
    override var code: String { "Co" }
    override var key: String { "\(code)\(colNo)" }
    public override var tokenKeys: [TokenKey] {
        cells.flatMap({ $0.tokenKeys }) + [
            headerTokenKey,
            footerTokenKey
        ]
    }
    override func createCores() -> [Core] {
        [HeaderCore(column: self),
         FooterCore(column: self)
        ] + cells.flatMap({ $0.createCores() })
    }
    override var chains: [Chain] { [chain, footerChain] + cells.map({ $0.chain }) }
    public override func newNo(type: String) -> Int { maxCellNo + 1 }

// Domain ==========================================================================================
    public override var properties: [String] { super.properties + ["name", "chain", "aggregate", "justify", "format", "footerChain"] }
    public override var children: [String] { super.children + ["cells"] }
    
// VariableTokenDelegate ===========================================================================
    var alias: String? { name }
}

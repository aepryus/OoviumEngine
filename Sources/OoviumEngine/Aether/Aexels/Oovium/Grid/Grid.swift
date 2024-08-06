//
//  Grid.swift
//  Oovium
//
//  Created by Joe Charlier on 12/30/16.
//  Copyright © 2016 Aepryus Software. All rights reserved.
//

import Acheron
import Aegean
import Foundation

public enum EqualMode {
	case close, down, right
	
	public var next: EqualMode {
		switch self {
			case .close:	return .down
			case .down:		return .right
			case .right:	return .close
		}
	}
}

public class Grid: Aexel {
	@objc public var typeID: Int = 0
	@objc public var rows: Int = 0
	@objc public var exposed: Bool = true
	
	@objc public var columns: [Column] = []
	@objc public var cells: [Cell] = []
	
	public var equalMode: EqualMode = .close
	
	public var hasFooter: Bool {
		return columns.first { $0.aggregate != .none && $0.aggregate != .running } != nil
	}

// Inits ===========================================================================================
	public required init(at: V2, aether: Aether) {
		rows = 1
		
		super.init(at: at, aether: aether)
		
		let column = Column(grid: self)
		column.parent = self
		column.name = Grid.name(n: 0)
		columns.append(column)
		let cell = Cell(grid: self)
		cell.parent = self
		cells.append(cell)
	}
	public required init(attributes: [String:Any], parent: Domain?) {
		super.init(attributes: attributes, parent: parent)
	}

// Other ===========================================================================================
    public func cellsForColumn(i: Int) -> [Cell] { cells.filter { $0.colNo == i } }
	public func numberCells() {
		for j in 0..<rows {
			for i in 0..<columns.count {
				let cellNo = columns.count*j+i
				cells[cellNo].colNo = i
				cells[cellNo].rowNo = j
			}
		}
	}
	public func addRow() -> [Cell] {
        var newCells: [Cell] = []
		rows += 1
		for colNo in 0 ..< columns.count {
			let cell: Cell = Cell(grid: self)
			cell.parent = self
			cell.colNo = colNo
			cell.rowNo = rows-1
			cells.append(cell)
            newCells.append(cell)
		}
//        aether.state.buildMemory()
//		columns.forEach {
//			if $0.calculated { $0.disseminate() }
//		}
        return newCells
	}
	public func deleteRow(rowNo: Int) {
//		rows -= 1
//        var toDestroy: [Tower] = []
//		for i in 0..<columns.count {
//			let cellNo: Int = (rowNo+1)*columns.count - 1 - i
//            toDestroy.append(cells[cellNo].tower)
//			cells.remove(at: cellNo)
//		}
//		numberCells()
//        aether.state.destroy(towers: toDestroy)
	}
	public func move(rowNo: Int, to: Int) {
		let cellNo: Int = rowNo*columns.count
		let moving: [Cell] = Array(cells[cellNo..<(cellNo+columns.count)])
		cells.removeSubrange(cellNo..<(cellNo+columns.count))
		cells.insert(contentsOf: moving, at: to*columns.count)
		numberCells()
	}
	
	public func addColumn() -> Column {
		let cc: Int = columns.count
		
		let column: Column = Column(grid: self)
		column.parent = self
		column.name = Grid.name(n: cc)
		columns.append(column)
		
		var nc: Int = cc
		for rowNo in 0..<rows {
			let cell: Cell = Cell(grid: self)
			cell.parent = self
			cell.colNo = cc
			cell.rowNo = rowNo
			cells.insert(cell, at: nc)
			nc += 1 + cc
		}
//        aether.state.buildMemory()
        
        return column
	}
	public func deleteColumn(_ column: Column) {
//		let colNo: Int = column.colNo
//        var toDestroy: [Tower] = []
//		for rowNo in 0..<rows {
//			let cellNo = columns.count*(rows-1-rowNo)+colNo
//            toDestroy.append(cells[cellNo].tower)
//			cells.remove(at: cellNo)
//		}
//        toDestroy.append(columns[colNo].chain.tower)
//        toDestroy.append(columns[colNo].footerChain.tower)
//		columns.remove(at: colNo)
//		numberCells()
//        aether.state.destroy(towers: toDestroy)
	}
	public func move(column: Column, to: Int) {
		let from = column.colNo
		columns.remove(at: from)
		columns.insert(column, at: to)
		for rowNo in 0..<rows {
			let fNo = rowNo*columns.count+from
			let tNo = rowNo*columns.count+to
			let cell = cells.remove(at: fNo)
			cells.insert(cell, at: tNo)
		}
		numberCells()
	}
	
	public func cell(colNo: Int, rowNo: Int) -> Cell {
		return cells[rowNo*columns.count + colNo]
	}
	public func column(colNo: Int) -> Column? {
		return columns[colNo]
	}
    public func column(tag: String) -> Column? { nil/*columns.first { $0.chain.tower.variableToken.tag == tag }*/ }
	public var maxCellNo: Int {
		var max: Int = 0
		cells.forEach {if $0.no > max {max = $0.no}}
		return max
	}
	public var maxColumnNo: Int {
		var max: Int = 0
		columns.forEach {if $0.no > max {max = $0.no}}
		return max
	}

// Events ==========================================================================================
	public override func onLoad() {}
	public override func onCreate() {
		exposed = true
	}

// Aexel ===========================================================================================
	public var towers: Set<Tower> {
		let towers: [Tower] = []
//		cells.forEach { towers.append($0.tower) }
//        columns.forEach { towers.append($0.chain.tower) }
//        columns.forEach { towers.append($0.footerChain.tower) }
		return Set<Tower>(towers)
	}
    public var chains: [Chain] {
        var chains: [Chain] = []
        cells.forEach { chains.append($0.chain) }
        columns.forEach { chains.append($0.chain) }
        return chains
    }
    
// Aexon ===========================================================================================
    public override var code: String { "Gr" }
    public override func newNo(type: String) -> Int {
        if type == "column" { return columns.count + 1 }
        else /*if key == "cell"*/ { return aether.newNo(type: type) }
    }
    override public func createCores() -> [Core] {
        columns.flatMap({ $0.createCores() })
        + cells.flatMap({ $0.createCores() })
    }

// Domain ==========================================================================================
    public override var properties: [String] { super.properties + ["typeID", "rows", "exposed"] }
	public override var children: [String] { super.children + ["columns", "cells"] }

// Static ==========================================================================================
	static func name(n: Int) -> String {
		var n: Int = n+1
		var name: String = String()
		while n != 0 {
			let c: Character = Character(UnicodeScalar((n-1)%26 + Int(("A" as UnicodeScalar).value))!)
			name += "\(c)"
			n = (n-1)/26
		}
		return String(name.reversed())
	}
}

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
//	@objc public var cells: [Cell] = []
	
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
		column.name = Grid.name(n: 1)
		columns.append(column)
	}
	public required init(attributes: [String:Any], parent: Domain?) {
		super.init(attributes: attributes, parent: parent)
	}

// Other ===========================================================================================
    public func column(colNo: Int) -> Column { columns[colNo-1] }
    public func cellsForColumn(colNo: Int) -> [Cell] { column(colNo: colNo).cells }
//	public func numberCells() {
//		for j in 0..<rows {
//			for i in 0..<columns.count {
//				let cellNo = columns.count*j+i
//				cells[cellNo].colNo = i
//				cells[cellNo].rowNo = j
//			}
//		}
//	}
    public func addRow() -> [Cell] {
        rows += 1

        return columns.map({ $0.addRow() })
    }
//
//        
//        
//        column.addRow()
//        var newCells: [Cell] = []
//		rows += 1
//		for _ in 0 ..< columns.count {
//			let cell: Cell = Cell(grid: self)
//			cell.parent = self
////			cell.colNo = colNo
////			cell.rowNo = rows-1
//			cells.append(cell)
//            newCells.append(cell)
//		}
////        aether.state.buildMemory()
//        columns.filter({ $0.calculated }).forEach {  $0.disseminate() }
//        return newCells
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
    public func move(rowNo: Int, toRowNo: Int) { columns.forEach { $0.move(rowNo: rowNo, toRowNo: toRowNo) } }
	
	public func addColumn() -> Column {
        let column: Column = Column(grid: self)
        columns.append(column)
        return column
        
        
//		let cc: Int = columns.count
//		
//		let column: Column = Column(grid: self)
//		column.parent = self
//		column.name = Grid.name(n: cc)
//		columns.append(column)
//		
//		var nc: Int = cc
//		for _ in 0..<rows {
//			let cell: Cell = Cell(grid: self)
//			cell.parent = self
////			cell.colNo = cc
////			cell.rowNo = rowNo
//			cells.insert(cell, at: nc)
//			nc += 1 + cc
//		}
////        aether.state.buildMemory()
//        
//        return column
	}
	public func deleteColumn(_ column: Column) -> [TokenKey] {
        let keys: [TokenKey] = column.tokenKeys
        columns.remove(object: column)
        return keys
//		let colNo: Int = column.colNo
//        var toDestroy: [TokenKey] = []
//		for rowNo in 0..<rows {
//			let cellNo = columns.count*(rows-1-rowNo)+colNo
//            toDestroy.append(cells[cellNo].chain.key!)
//			cells.remove(at: cellNo)
//		}
//        toDestroy.append(columns[colNo].headerTokenKey)
//        toDestroy.append(columns[colNo].footerTokenKey)
//		columns.remove(at: colNo)
////		numberCells()
//        return toDestroy
	}
	public func move(column: Column, to: Int) {
		let from = column.colNo
		columns.remove(at: from-1)
		columns.insert(column, at: to)
//		for rowNo in 0..<rows {
//			let fNo = rowNo*columns.count+from
//			let tNo = rowNo*columns.count+to
//			let cell = cells.remove(at: fNo)
//			cells.insert(cell, at: tNo)
//		}
//		numberCells()
	}
	
    public func cell(colNo: Int, rowNo: Int) -> Cell { columns[colNo-1].cells[rowNo-1] }
    public func column(tag: String) -> Column? { columns.first { $0.chain.key!.tag == tag } }
    public var maxCellNo: Int { columns.maximum({ $0.maxCellNo }) ?? 0 }
    public var maxColumnNo: Int { columns.maximum({ $0.colNo }) ?? 0 }

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
    public var chains: [Chain] { columns.flatMap { $0.chains } }
    
// Aexon ===========================================================================================
    public override var code: String { "Gr" }
    public override var tokenKeys: [TokenKey] { columns.flatMap({ $0.tokenKeys }) }
    public override func createCores() -> [Core] { columns.flatMap({ $0.createCores() }) }
    public override func newNo(type: String) -> Int { maxColumnNo + 1 }

// Domain ==========================================================================================
    public override var properties: [String] { super.properties + ["typeID", "rows", "exposed"] }
	public override var children: [String] { super.children + ["columns"] }

// Static ==========================================================================================
	static func name(n: Int) -> String {
		var n: Int = n
		var name: String = String()
		while n != 0 {
			let c: Character = Character(UnicodeScalar((n-1)%26 + Int(("A" as UnicodeScalar).value))!)
			name += "\(c)"
			n = (n-1)/26
		}
		return String(name.reversed())
	}
}

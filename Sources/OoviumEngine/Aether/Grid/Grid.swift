//
//  Grid.swift
//  Oovium
//
//  Created by Joe Charlier on 12/30/16.
//  Copyright © 2016 Aepryus Software. All rights reserved.
//

import Acheron
import Foundation

public enum EqualMode {
	case close, down, right
	
	var next: EqualMode {
		switch self {
			case .close:	return .down
			case .down:		return .right
			case .right:	return .close
		}
	}
}

public final class Grid: Aexel {
	@objc public var typeID: Int = 0
	@objc public var rows: Int = 0
	@objc public var exposed: Bool = true
	
	@objc public var columns: [Column] = []
	@objc public var cells: [Cell] = []
	
	public var equalMode: EqualMode = .close
	
	var hasFooter: Bool {
		return columns.first { $0.aggregate != .none && $0.aggregate != .running } != nil
	}

// Inits ===========================================================================================
	public required init(no: Int, at: V2, aether: Aether) {
		rows = 1
		
		super.init(no: no, at: at, aether: aether)
		
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
	func numberCells() {
		for j in 0..<rows {
			for i in 0..<columns.count {
				let cellNo = columns.count*j+i
				cells[cellNo].colNo = i
				cells[cellNo].rowNo = j
			}
		}
	}
	func addRow() {
		rows += 1
		for colNo in 0 ..< columns.count {
			let cell: Cell = Cell(grid: self)
			cell.parent = self
			cell.colNo = colNo
			cell.rowNo = rows-1
			cells.append(cell)
			aether.register(tower: cell.tower)
		}
		aether.buildMemory()
		columns.forEach {
			if $0.calculated {$0.disseminate()}
			$0.render()
		}
	}
	func deleteRow(rowNo: Int) {
		rows -= 1
		for i in 0..<columns.count {
			let cellNo: Int = (rowNo+1)*columns.count - 1 - i
			aether.deregister(tower: cells[cellNo].tower)
			cells.remove(at: cellNo)
		}
		numberCells()
		aether.buildMemory()
	}
	func move(rowNo: Int, to: Int) {
		let cellNo: Int = rowNo*columns.count
		let moving: [Cell] = Array(cells[cellNo..<(cellNo+columns.count)])
		cells.removeSubrange(cellNo..<(cellNo+columns.count))
		cells.insert(contentsOf: moving, at: to*columns.count)
		numberCells()
	}
	
	func addColumn() {
		let cc: Int = columns.count
		
		let column: Column = Column(grid: self)
		column.parent = self
		column.name = Grid.name(n: cc)
		columns.append(column)
		aether.register(tower: column.footerTower)
		
		var nc: Int = cc
		for rowNo in 0..<rows {
			let cell: Cell = Cell(grid: self)
			cell.parent = self
			cell.colNo = cc
			cell.rowNo = rowNo
			cells.insert(cell, at: nc)
			aether.register(tower: cell.tower)
			nc += 1 + cc
		}
		aether.buildMemory()
	}
	func deleteColumn(_ column: Column) {
		let colNo: Int = column.colNo
		for rowNo in 0..<rows {
			let cellNo = columns.count*(rows-1-rowNo)+colNo
			let cell: Cell = cells[cellNo]
			aether.deregister(tower: cell.tower)
			cells.remove(at: cellNo)
		}
		aether.deregister(tower: column.tower)
		if hasFooter {aether.deregister(tower: columns[colNo].footerTower)}
		columns.remove(at: colNo)
		numberCells()
		aether.buildMemory()
	}
	func move(column: Column, to: Int) {
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
	
	func cell(colNo: Int, rowNo: Int) -> Cell {
		return cells[rowNo*columns.count + colNo]
	}
	func column(colNo: Int) -> Column? {
		return columns[colNo]
	}
	func column(tag: String) -> Column? {
		return columns.first {$0.token.tag == tag}
	}
	var maxCellNo: Int {
		var max: Int = 0
		cells.forEach {if $0.no > max {max = $0.no}}
		return max
	}
	var maxColumnNo: Int {
		var max: Int = 0
		columns.forEach {if $0.no > max {max = $0.no}}
		return max
	}

// Events ==========================================================================================
	override public func onLoad() {}
	override public func onCreate() {
		exposed = true
	}

// Aexel ===========================================================================================
	public override var towers: Set<Tower> {
		var towers: [Tower] = []
		cells.forEach { towers.append($0.tower) }
//		columns.forEach { towers.append($0.tower) }
		columns.forEach { towers.append($0.footerTower) }
		return Set<Tower>(towers)
	}

// Domain ==========================================================================================
	override public var properties: [String] {
		return super.properties + ["typeID", "rows", "exposed"]
	}
	override public var children: [String] {
		return super.children + ["columns", "cells"]
	}

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

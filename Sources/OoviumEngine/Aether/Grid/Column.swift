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

@objc enum OOAggregate: Int {
	case none, sum, average, running, count, match
}
@objc enum OOJustify: Int {
	case left, center, right
}

public final class Column: Domain, TowerDelegate {
	@objc public var no: Int = 0
	@objc var name: String = "" {
		didSet {
			token.label = name
			chain.label = name
		}
	}
	var def: Def = RealDef.def
	@objc var chain: Chain = Chain()
	@objc var aggregate: OOAggregate = .none
	@objc var justify: OOJustify = .right
	@objc var format: String = ""
	
//	var _width: CGFloat? = nil
//	var width: CGFloat {
//		if _width == nil {
//			renderWidth()
//		}
//		return _width!
//	}
//	var _headerWidth: CGFloat? = nil
//	var headerWidth: CGFloat {
//		get {
//			if _headerWidth == nil {
//				renderHeaderWidth()
//			}
//			return _headerWidth!
//		}
//	}
//	var _footerWidth: CGFloat? = nil
//	var footerWidth: CGFloat {
//		get {
//			renderFooterWidth()
//			return _footerWidth!
//		}
//	}
	var footerChain: Chain = Chain()
	
	fileprivate lazy var header: Header = Header()
	
	lazy var tower: Tower = Tower(aether: grid.aether, token: grid.aether.variableToken(tag: "Gr\(grid.no).Co\(no)"), delegate: header)
	lazy var token: VariableToken = grid.aether.variableToken(tag: "Gr\(grid.no).Co\(no)", label: name)
	lazy var footerTower: Tower = Tower(aether: grid.aether, token: grid.aether.variableToken(tag: "Gr\(grid.no).Ft\(no)"), delegate: self)
	
	var grid: Grid {
		return parent as! Grid
	}
	var calculated: Bool {
		return chain.tokens.count > 0
	}
	var hasFooter: Bool {
		return aggregate != .none && aggregate != .running
	}
	
//	var alignment: NSTextAlignment {
//		switch justify {
//			case .left: return .left
//			case .center: return .center
//			case .right: return .right
//		}
//	}
	var colNo: Int {
		for i in 0..<grid.columns.count {
			if self === grid.columns[i] {return i}
		}
		fatalError()
	}
	
	func render() {
		if aggregate == .none {
			grid.aether.deregister(tower: footerTower)
		} else {
			grid.aether.register(tower: footerTower)
			grid.aether.buildMemory()
			footerTower.buildStream()
			grid.aether.evaluate()
		}
	}
//	func renderHeaderWidth() {
//		let pen: Pen = Pen(font: UIFont(name: "Verdana-Bold", size: 15)!)
//		_headerWidth = (name as NSString).size(pen: pen).width+20
//	}
//	func renderFooterWidth() {
//		if aggregate == .none || aggregate == .running {
//			_footerWidth = 0
//		} else {
//			_footerWidth = (footerTower.obje.display as NSString).size(pen: Pen()).width + 12
//		}
//	}

// Inits ===========================================================================================
	public init(grid: Grid) {
		no = grid.maxColumnNo + 1
		super.init()
		parent = grid
		chain.tower = tower
		chain.alwaysShow = true
		footerChain.tower = footerTower
	}
	public required init(attributes: [String:Any], parent: Domain?) {
		super.init(attributes: attributes, parent: parent)
	}
	
	// Other ===========================================================================================
	func disseminate() {
		guard chain.tokens.count > 0 else {return}
		
		if aggregate != .running {
			for i in 0..<grid.rows {
				let cell = grid.cell(colNo: colNo, rowNo: i)
				cell.chain.clear()
				
				for token in chain.tokens {
					if let column = grid.column(tag: token.tag) {
						let other: Cell = grid.cell(colNo: column.colNo, rowNo: i)
						cell.chain.post(token: other.tower.variableToken)
					} else {
						cell.chain.post(token: token)
					}
				}
			}
			if aggregate == .match {
				footerChain.clear()
				for token in chain.tokens {
					if let column = grid.column(tag: token.tag) {
						footerChain.post(token: column.footerTower.variableToken)
					} else {
						footerChain.post(token: token)
					}
				}
			}
			
		} else {
			for i in 0..<grid.rows {
				let cell = grid.cell(colNo: colNo, rowNo: i)
				cell.chain.clear()
				
				for token in chain.tokens {
					if let column = grid.column(tag: token.tag) {
						let other: Cell = grid.cell(colNo: column.colNo, rowNo: i)
						cell.chain.post(token: other.tower.variableToken)
					} else {
						cell.chain.post(token: token)
					}
				}
				if i != 0 {
					cell.chain.post(token: Token.add)
					let above: Cell = grid.cell(colNo: colNo, rowNo: i-1)
					cell.chain.post(token: above.tower.variableToken)
				}
			}
		}
	}
	func calculate() {
		var towers: Set<Tower> = Set<Tower>()
		for i in 0..<grid.rows {
			let cell = grid.cell(colNo: colNo, rowNo: i)
			towers.formUnion(cell.tower.allDownstream())
		}
		grid.aether.evaluate(towers: towers)
	}
//	func renderWidth() {
//		var width = max(90, headerWidth)
//		width = max(width, footerWidth)
//		for i in 0..<grid.rows {
//			let cell: Cell = grid.cell(colNo: colNo, rowNo: i)
//			width = max(width, cell.width)
//		}
//		_width = width
//	}
	
	// Events ==========================================================================================
	public override func onLoad() {
		chain.tower = tower
		footerChain.tower = footerTower
		chain.alwaysShow = true
		chain.label = name
		token.label = name
	}
	
	// Domain ==========================================================================================
	override public var properties: [String] {
		return super.properties + ["no", "name", "chain", "aggregate", "justify", "format"]
	}
	
	
	// Compiling =======================================================================================
	private func compileNON() -> UnsafeMutablePointer<Lambda>? {
		let memory = tower.aether.memory
		let vi: mnimi = AEMemoryIndexForName(memory, footerTower.variableToken.tag.toInt8())
		
		let c: UnsafeMutablePointer<Obj> = UnsafeMutablePointer<Obj>.allocate(capacity: 0)
		let v: UnsafeMutablePointer<mnimi> = UnsafeMutablePointer<mnimi>.allocate(capacity: 0)
		let m: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: 0)
		
		let lambda: UnsafeMutablePointer<Lambda> = AELambdaCreate(mnimi(vi), c, UInt8(0), v, UInt8(0), m, UInt8(0), nil)
		
		c.deallocate()
		v.deallocate()
		m.deallocate()
		
		return lambda
	}
	private func compileSUM() -> UnsafeMutablePointer<Lambda>? {
		let memory = tower.aether.memory
		let vi: mnimi = AEMemoryIndexForName(memory, footerTower.variableToken.tag.toInt8())
		let c: UnsafeMutablePointer<Obj> = UnsafeMutablePointer<Obj>.allocate(capacity: 0)
		
		let vn = grid.rows
		let v: UnsafeMutablePointer<mnimi> = UnsafeMutablePointer<mnimi>.allocate(capacity: vn)
		for i in 0..<vn {
			let cell: Cell = grid.cell(colNo: colNo, rowNo: i)
			v[i] = AEMemoryIndexForName(memory, cell.tower.variableToken.tag.toInt8())
		}
		
		let mn = 2*vn - 1
		let m: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: mn)
		
		m[0] = UInt8(AEMorphNumVarForce.rawValue)
		for i in 1..<vn {
			m[2*i-1] = UInt8(AEMorphNumVarForce.rawValue)
			m[2*i] = UInt8(AEMorphAdd.rawValue)
		}
		
		let lambda: UnsafeMutablePointer<Lambda> = AELambdaCreate(mnimi(vi), c, UInt8(0), v, UInt8(vn), m, UInt8(mn), nil)
		
		c.deallocate()
		v.deallocate()
		m.deallocate()
		
		return lambda
	}
	private func compileAVG() -> UnsafeMutablePointer<Lambda>? {
		let memory = tower.aether.memory
		let vi: mnimi = AEMemoryIndexForName(memory, footerTower.variableToken.tag.toInt8())
		
		let cn: Int = 1
		let c: UnsafeMutablePointer<Obj> = UnsafeMutablePointer<Obj>.allocate(capacity: cn)
		c[0] = AEObjReal(Double(grid.rows))
		
		let vn = grid.rows
		let v: UnsafeMutablePointer<mnimi> = UnsafeMutablePointer<mnimi>.allocate(capacity: vn)
		for i in 0..<vn {
			let cell: Cell = grid.cell(colNo: colNo, rowNo: i)
			v[i] = AEMemoryIndexForName(memory, cell.tower.variableToken.tag.toInt8())
		}
		
		let mn = 2*vn - 1 + 2
		let m: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: mn)
		
		m[0] = UInt8(AEMorphNumVar.rawValue)
		for i in 1..<vn {
			m[2*i-1] = UInt8(AEMorphNumVar.rawValue)
			m[2*i] = UInt8(AEMorphAdd.rawValue)
		}
		m[2*vn-1] = UInt8(AEMorphNumCns.rawValue)
		m[2*vn] = UInt8(AEMorphDiv.rawValue)
		
		let lambda: UnsafeMutablePointer<Lambda> = AELambdaCreate(mnimi(vi), c, UInt8(cn), v, UInt8(vn), m, UInt8(mn), nil)
		
		c.deallocate()
		v.deallocate()
		m.deallocate()
		
		return lambda
	}
	private func compileRUN() -> UnsafeMutablePointer<Lambda>? {
		let memory = tower.aether.memory
		let vi: mnimi = AEMemoryIndexForName(memory, footerTower.variableToken.tag.toInt8())
		
		let c: UnsafeMutablePointer<Obj> = UnsafeMutablePointer<Obj>.allocate(capacity: 0)
		let v: UnsafeMutablePointer<mnimi> = UnsafeMutablePointer<mnimi>.allocate(capacity: 0)
		let m: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: 0)
		
		let lambda: UnsafeMutablePointer<Lambda> = AELambdaCreate(mnimi(vi), c, UInt8(0), v, UInt8(0), m, UInt8(0), nil)
		
		c.deallocate()
		v.deallocate()
		m.deallocate()
		
		return lambda
	}
	private func compileMTC() -> UnsafeMutablePointer<Lambda>? {
		return footerChain.compile(name: footerTower.variableToken.tag)
	}
	private func compuleCNT() -> UnsafeMutablePointer<Lambda>? {
		let memory = tower.aether.memory
		let vi: mnimi = AEMemoryIndexForName(memory, footerTower.variableToken.tag.toInt8())
		
		let cn: Int = 1
		let c: UnsafeMutablePointer<Obj> = UnsafeMutablePointer<Obj>.allocate(capacity: cn)
		c[0] = AEObjReal(Double(grid.rows))
		
		let vn = 0
		let v: UnsafeMutablePointer<mnimi> = UnsafeMutablePointer<mnimi>.allocate(capacity: vn)
		
		let mn = 1
		let m: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: mn)
		
		m[0] = UInt8(AEMorphNumCns.rawValue)
		
		let lambda: UnsafeMutablePointer<Lambda> = AELambdaCreate(mnimi(vi), c, UInt8(cn), v, UInt8(vn), m, UInt8(mn), nil)
		
		c.deallocate()
		v.deallocate()
		m.deallocate()
		
		return lambda
	}
	
	public func compile(name: String) -> UnsafeMutablePointer<Lambda>? {
		switch aggregate {
			case .none: 	return compileNON()
			case .sum: 		return compileSUM()
			case .average: 	return compileAVG()
			case .running: 	return compileRUN()
			case .match: 	return compileMTC()
			case .count: 	return compuleCNT()
		}
	}
	
// TowerDelegate ===================================================================================
	func buildUpstream(tower: Tower) {
		guard aggregate != .none && aggregate != .running && aggregate != .match else { return }
		tower.abstractUp()
		for i in 0..<grid.rows {
			let cell = grid.cell(colNo: colNo, rowNo: i)
			cell.tower.attach(tower)
		}
	}
	func renderDisplay(tower: Tower) -> String {
		return tower.obje.display
	}
	func buildWorker(tower: Tower) {
		let lambda: UnsafeMutablePointer<Lambda>? = compile(name: tower.name)
		tower.task = lambda != nil ? AETaskCreateLambda(lambda) : AETaskCreateNull()
		AETaskSetLabels(tower.task, tower.variableToken.tag.toInt8(), "\(tower.variableToken.tag) = SUM(Gr\(grid.no).Co\(no)".toInt8())
	}
	func workerCompleted(tower: Tower, askedBy: Tower) -> Bool {
		return AEMemoryLoaded(tower.aether.memory, tower.index) != 0
	}
	func resetWorker(tower: Tower) {
		AEMemoryUnfix(tower.aether.memory, tower.index)
	}
	func executeWorker(tower: Tower) {
		AETaskExecute(tower.task, tower.aether.memory)
		AEMemoryFix(tower.aether.memory, tower.index)
		tower.variableToken.label = tower.obje.display
		tower.variableToken.def = tower.obje.def
	}
}

fileprivate class Header: TowerDelegate {}

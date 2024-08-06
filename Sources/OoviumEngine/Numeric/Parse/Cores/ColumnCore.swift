//
//  ColumnCore.swift
//  OoviumEngine
//
//  Created by Joe Charlier on 8/5/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import Aegean
import Foundation

class ColumnCore: Core {
    let column: Column
    
    init(column: Column) {
        self.column = column
    }
    
    public func disseminate() {
        guard !column.chain.isEmpty else { return }
        
//        if aggregate != .running {
//            for i in 0..<grid.rows {
//                let cell = grid.cell(colNo: colNo, rowNo: i)
//                cell.chain.clear()
//
//                for token in chain.tokens {
//                    if let column = grid.column(tag: token.tag) {
//                        let other: Cell = grid.cell(colNo: column.colNo, rowNo: i)
//                        cell.chain.post(token: other.tower.variableToken)
//                    } else {
//                        cell.chain.post(token: token)
//                    }
//                }
//            }
//            if aggregate == .match {
//                footerChain.clear()
//                for token in chain.tokens {
//                    if let column = grid.column(tag: token.tag) {
//                        footerChain.post(token: column.footerChain.tower.variableToken)
//                    } else {
//                        footerChain.post(token: token)
//                    }
//                }
//            }
//
//        } else {
//            for i in 0..<grid.rows {
//                let cell = grid.cell(colNo: colNo, rowNo: i)
//                cell.chain.clear()
//
//                for token in chain.tokens {
//                    if let column = grid.column(tag: token.tag) {
//                        let other: Cell = grid.cell(colNo: column.colNo, rowNo: i)
//                        cell.chain.post(token: other.tower.variableToken)
//                    } else {
//                        cell.chain.post(token: token)
//                    }
//                }
//                if i != 0 {
//                    cell.chain.post(token: Token.add)
//                    let above: Cell = grid.cell(colNo: colNo, rowNo: i-1)
//                    cell.chain.post(token: above.tower.variableToken)
//                }
//            }
//        }
    }
    public func calculate() {
//        var towers: Set<Tower> = Set<Tower>()
//        for i in 0..<grid.rows {
//            let cell = grid.cell(colNo: colNo, rowNo: i)
//            towers.formUnion(cell.tower.allDownstream())
//        }
//        Tower.evaluate(towers: towers)
    }

// Compiling =======================================================================================
    private func compileNON() -> UnsafeMutablePointer<Lambda>? {
//        let memory = aether.state.memory
//        let vi: mnimi = AEMemoryIndexForName(memory, footerChain.tower.variableToken.tag.toInt8())
//
//        let c: UnsafeMutablePointer<Obj> = UnsafeMutablePointer<Obj>.allocate(capacity: 0)
//        let v: UnsafeMutablePointer<mnimi> = UnsafeMutablePointer<mnimi>.allocate(capacity: 0)
//        let m: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: 0)
//
//        let lambda: UnsafeMutablePointer<Lambda> = AELambdaCreate(mnimi(vi), c, UInt8(0), v, UInt8(0), m, UInt8(0), nil)
//
//        c.deallocate()
//        v.deallocate()
//        m.deallocate()
//
//        return lambda
        nil
    }
    private func compileSUM() -> UnsafeMutablePointer<Lambda>? {
//        let memory = aether.state.memory
//        let vi: mnimi = AEMemoryIndexForName(memory, footerChain.tower.variableToken.tag.toInt8())
//        let c: UnsafeMutablePointer<Obj> = UnsafeMutablePointer<Obj>.allocate(capacity: 0)
//
//        let vn = grid.rows
//        let v: UnsafeMutablePointer<mnimi> = UnsafeMutablePointer<mnimi>.allocate(capacity: vn)
//        for i in 0..<vn {
//            let cell: Cell = grid.cell(colNo: colNo, rowNo: i)
//            v[i] = AEMemoryIndexForName(memory, cell.tower.variableToken.tag.toInt8())
//        }
//
//        let mn = 2*vn - 1
//        let m: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: mn)
//
//        m[0] = UInt8(AEMorphNumVarForce.rawValue)
//        for i in 1..<vn {
//            m[2*i-1] = UInt8(AEMorphNumVarForce.rawValue)
//            m[2*i] = UInt8(AEMorphAdd.rawValue)
//        }
//
//        let lambda: UnsafeMutablePointer<Lambda> = AELambdaCreate(mnimi(vi), c, UInt8(0), v, UInt8(vn), m, UInt8(mn), nil)
//
//        c.deallocate()
//        v.deallocate()
//        m.deallocate()
//
//        return lambda
        nil
    }
    private func compileAVG() -> UnsafeMutablePointer<Lambda>? {
//        let memory = aether.state.memory
//        let vi: mnimi = AEMemoryIndexForName(memory, footerChain.tower.variableToken.tag.toInt8())
//
//        let cn: Int = 1
//        let c: UnsafeMutablePointer<Obj> = UnsafeMutablePointer<Obj>.allocate(capacity: cn)
//        c[0] = AEObjReal(Double(grid.rows))
//
//        let vn = grid.rows
//        let v: UnsafeMutablePointer<mnimi> = UnsafeMutablePointer<mnimi>.allocate(capacity: vn)
//        for i in 0..<vn {
//            let cell: Cell = grid.cell(colNo: colNo, rowNo: i)
//            v[i] = AEMemoryIndexForName(memory, cell.tower.variableToken.tag.toInt8())
//        }
//
//        let mn = 2*vn - 1 + 2
//        let m: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: mn)
//
//        m[0] = UInt8(AEMorphNumVar.rawValue)
//        for i in 1..<vn {
//            m[2*i-1] = UInt8(AEMorphNumVar.rawValue)
//            m[2*i] = UInt8(AEMorphAdd.rawValue)
//        }
//        m[2*vn-1] = UInt8(AEMorphNumCns.rawValue)
//        m[2*vn] = UInt8(AEMorphDiv.rawValue)
//
//        let lambda: UnsafeMutablePointer<Lambda> = AELambdaCreate(mnimi(vi), c, UInt8(cn), v, UInt8(vn), m, UInt8(mn), nil)
//
//        c.deallocate()
//        v.deallocate()
//        m.deallocate()
//
//        return lambda
        nil
    }
    private func compileRUN() -> UnsafeMutablePointer<Lambda>? {
//        let memory = aether.state.memory
//        let vi: mnimi = AEMemoryIndexForName(memory, footerChain.tower.variableToken.tag.toInt8())
//
//        let c: UnsafeMutablePointer<Obj> = UnsafeMutablePointer<Obj>.allocate(capacity: 0)
//        let v: UnsafeMutablePointer<mnimi> = UnsafeMutablePointer<mnimi>.allocate(capacity: 0)
//        let m: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: 0)
//
//        let lambda: UnsafeMutablePointer<Lambda> = AELambdaCreate(mnimi(vi), c, UInt8(0), v, UInt8(0), m, UInt8(0), nil)
//
//        c.deallocate()
//        v.deallocate()
//        m.deallocate()
//
//        return lambda
        nil
    }
    private func compileMTC() -> UnsafeMutablePointer<Lambda>? { nil
//        return footerChain.compile(name: footerTower.variableToken.tag)
    }
    private func compuleCNT() -> UnsafeMutablePointer<Lambda>? {
//        let memory = aether.state.memory
//        let vi: mnimi = AEMemoryIndexForName(memory, footerChain.tower.variableToken.tag.toInt8())
//
//        let cn: Int = 1
//        let c: UnsafeMutablePointer<Obj> = UnsafeMutablePointer<Obj>.allocate(capacity: cn)
//        c[0] = AEObjReal(Double(grid.rows))
//
//        let vn = 0
//        let v: UnsafeMutablePointer<mnimi> = UnsafeMutablePointer<mnimi>.allocate(capacity: vn)
//
//        let mn = 1
//        let m: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: mn)
//
//        m[0] = UInt8(AEMorphNumCns.rawValue)
//
//        let lambda: UnsafeMutablePointer<Lambda> = AELambdaCreate(mnimi(vi), c, UInt8(cn), v, UInt8(vn), m, UInt8(mn), nil)
//
//        c.deallocate()
//        v.deallocate()
//        m.deallocate()
//
//        return lambda
        nil
    }
    
    public func compile(name: String) -> UnsafeMutablePointer<Lambda>? {
        switch column.aggregate {
            case .none:     return compileNON()
            case .sum:         return compileSUM()
            case .average:     return compileAVG()
            case .running:     return compileRUN()
            case .match:     return compileMTC()
            case .count:     return compuleCNT()
        }
    }
    
// Core ===================================================================================
    override func buildUpstream(tower: Tower) {
//        guard aggregate != .none && aggregate != .running && aggregate != .match else { return }
//        tower.abstractUp()
//        for i in 0..<grid.rows {
//            let cell = grid.cell(colNo: colNo, rowNo: i)
//            cell.tower.attach(tower)
//        }
    }
    override func renderDisplay(tower: Tower) -> String { tower.obje.display }
    override func renderTask(tower: Tower) -> UnsafeMutablePointer<Task>? {
        let lambda: UnsafeMutablePointer<Lambda>? = compile(name: tower.name)
        let task: UnsafeMutablePointer<Task> = lambda != nil ? AETaskCreateLambda(lambda) : AETaskCreateNull()
        AETaskSetLabels(task, tower.variableToken.tag.toInt8(), "\(tower.variableToken.tag) = SUM(\(column.fullKey)".toInt8())
        return task
    }
    override func taskCompleted(tower: Tower, askedBy: Tower) -> Bool {
        AEMemoryLoaded(tower.memory, tower.index) != 0
    }
    override func resetTask(tower: Tower) {
        AEMemoryUnfix(tower.memory, tower.index)
    }
    override func executeTask(tower: Tower) {
        AETaskExecute(tower.task, tower.memory)
        AEMemoryFix(tower.memory, tower.index)
        tower.variableToken.def = tower.obje.def
    }
    
// VariableTokenDelegate ===========================================================================
    public var alias: String? { column.name }
}

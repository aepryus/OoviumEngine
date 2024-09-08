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
    
    init(column: Column) { self.column = column }
    
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

// Compiling =======================================================================================
    private func compileNON() -> UnsafeMutablePointer<Lambda>? {
        let memory: UnsafeMutablePointer<Memory> = aetherExe.memory
        let vi: mnimi = AEMemoryIndexForName(memory, column.footerChain.key!.tag.toInt8())
        return AELambdaCreate(vi, nil, 0, nil, 0, nil, 0, nil)
    }
    private func compileSUM() -> UnsafeMutablePointer<Lambda>? {
        let memory: UnsafeMutablePointer<Memory> = aetherExe.memory
        let vi: mnimi = AEMemoryIndexForName(memory, column.footerChain.key!.tag.toInt8())
        
        let vn: Int = column.grid.rows
        let v: UnsafeMutablePointer<mnimi> = UnsafeMutablePointer<mnimi>.allocate(capacity: vn)
        defer { v.deallocate() }
        for i: Int in 0..<vn {
            let cell: Cell = column.grid.cell(colNo: column.colNo, rowNo: i)
            v[i] = AEMemoryIndexForName(memory, cell.chain.key!.tag.toInt8())
        }

        let mn: Int = 2*vn - 1
        let m: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: mn)
        defer { m.deallocate() }

        m[0] = UInt8(MorphNumVarForce.rawValue)
        for i: Int in 1..<vn {
            m[2*i-1] = UInt8(MorphNumVarForce.rawValue)
            m[2*i] = UInt8(MorphAdd.rawValue)
        }

        return AELambdaCreate(mnimi(vi), nil, 0, v, UInt8(vn), m, UInt8(mn), nil)
    }
    private func compileAVG() -> UnsafeMutablePointer<Lambda>? {
        let memory: UnsafeMutablePointer<Memory> = aetherExe.memory
        let vi: mnimi = AEMemoryIndexForName(memory, column.footerChain.key!.tag.toInt8())
        
        let cn: Int = 1
        let c: UnsafeMutablePointer<Obj> = UnsafeMutablePointer<Obj>.allocate(capacity: cn)
        defer { c.deallocate() }
        c[0] = AEObjReal(Double(column.grid.rows))

        let vn: Int = column.grid.rows
        let v: UnsafeMutablePointer<mnimi> = UnsafeMutablePointer<mnimi>.allocate(capacity: vn)
        defer { v.deallocate() }
        for i: Int in 0..<vn {
            let cell: Cell = column.grid.cell(colNo: column.colNo, rowNo: i)
            v[i] = AEMemoryIndexForName(memory, cell.chain.key!.tag.toInt8())
        }

        let mn: Int = 2*vn - 1 + 2
        let m: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: mn)
        defer { m.deallocate() }

        m[0] = UInt8(MorphNumVarForce.rawValue)
        for i: Int in 1..<vn {
            m[2*i-1] = UInt8(MorphNumVarForce.rawValue)
            m[2*i] = UInt8(MorphAdd.rawValue)
        }
        m[2*vn-1] = UInt8(MorphNumCns.rawValue)
        m[2*vn] = UInt8(MorphDiv.rawValue)

        return AELambdaCreate(mnimi(vi), c, UInt8(cn), v, UInt8(vn), m, UInt8(mn), nil)
    }
    private func compileRUN() -> UnsafeMutablePointer<Lambda>? {
        let memory: UnsafeMutablePointer<Memory> = aetherExe.memory
        let vi: mnimi = AEMemoryIndexForName(memory, column.footerChain.key!.tag.toInt8())
        
        let vn: Int = column.grid.rows
        let v: UnsafeMutablePointer<mnimi> = UnsafeMutablePointer<mnimi>.allocate(capacity: vn)
        defer { v.deallocate() }
        for i: Int in 0..<vn {
            let cell: Cell = column.grid.cell(colNo: column.colNo, rowNo: i)
            v[i] = AEMemoryIndexForName(memory, cell.chain.key!.tag.toInt8())
        }

        let mn: Int = vn
        let m: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: mn)
        defer { m.deallocate() }

        for i: Int in 0..<vn {
            m[i] = UInt8(MorphNumVarForce.rawValue)
        }

        return AELambdaCreate(mnimi(vi), nil, 0, v, UInt8(vn), m, UInt8(mn), nil)
    }
    private func compileMTC() -> UnsafeMutablePointer<Lambda>? {
        nil
//        column.footerChain.compile().compile(name: <#T##String#>, tower: <#T##Tower#>)
    }
    private func compileCNT() -> UnsafeMutablePointer<Lambda>? {
        let memory: UnsafeMutablePointer<Memory> = aetherExe.memory
        let vi: mnimi = AEMemoryIndexForName(memory, column.footerChain.key!.tag.toInt8())
        
        let cn: Int = 1
        let c: UnsafeMutablePointer<Obj> = UnsafeMutablePointer<Obj>.allocate(capacity: cn)
        defer { c.deallocate() }
        c[0] = AEObjReal(Double(column.grid.rows))

        let vn: Int = 0
        let v: UnsafeMutablePointer<mnimi> = UnsafeMutablePointer<mnimi>.allocate(capacity: vn)
        defer { v.deallocate() }

        let mn: Int = 1
        let m: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: mn)
        defer { m.deallocate() }

        m[0] = UInt8(MorphNumCns.rawValue)

        return AELambdaCreate(mnimi(vi), c, UInt8(cn), v, UInt8(vn), m, UInt8(mn), nil)
    }
    
    public func compile(name: String) -> UnsafeMutablePointer<Lambda>? {
        switch column.aggregate {
            case .none:     return compileNON()
            case .sum:      return compileSUM()
            case .average:  return compileAVG()
            case .running:  return compileRUN()
            case .match:    return compileMTC()
            case .count:    return compileCNT()
        }
    }
    
// Core ===================================================================================
    override var key: TokenKey { column.footerChain.key! }
    
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

//
//  FooterCore.swift
//  OoviumEngine
//
//  Created by Joe Charlier on 10/6/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import Aegean

class FooterCore: Core {
    let column: Column
    
    var tokens: [Token] = []
    
    init(column: Column) { self.column = column }
    
// Compiling =======================================================================================
    private func compileNON() -> UnsafeMutablePointer<Lambda>? {
        let memory: UnsafeMutablePointer<Memory> = citadel.memory
        let vi: mnimi = AEMemoryIndexForName(memory, column.footerTokenKey.tag.toInt8())
        return AELambdaCreate(vi, nil, 0, nil, 0, nil, 0, nil)
    }
    private func compileSUM() -> UnsafeMutablePointer<Lambda>? {
        let memory: UnsafeMutablePointer<Memory> = citadel.memory
        let vi: mnimi = AEMemoryIndexForName(memory, column.footerTokenKey.tag.toInt8())
        
        let vn: Int = column.grid.rows
        let v: UnsafeMutablePointer<mnimi> = UnsafeMutablePointer<mnimi>.allocate(capacity: vn)
        defer { v.deallocate() }
        for i: Int in 0..<vn {
            let cell: Cell = column.grid.cell(colNo: column.colNo, rowNo: i+1)
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
        let memory: UnsafeMutablePointer<Memory> = citadel.memory
        let vi: mnimi = AEMemoryIndexForName(memory, column.footerTokenKey.tag.toInt8())
        
        let cn: Int = 1
        let c: UnsafeMutablePointer<Obj> = UnsafeMutablePointer<Obj>.allocate(capacity: cn)
        defer { c.deallocate() }
        c[0] = AEObjReal(Double(column.grid.rows))

        let vn: Int = column.grid.rows
        let v: UnsafeMutablePointer<mnimi> = UnsafeMutablePointer<mnimi>.allocate(capacity: vn)
        defer { v.deallocate() }
        for i: Int in 0..<vn {
            let cell: Cell = column.grid.cell(colNo: column.colNo, rowNo: i+1)
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
    private func compileMTC() -> UnsafeMutablePointer<Lambda>? {
        guard let tower: Tower = citadel.tower(key: column.footerTokenKey) else { return nil }
        let chain: Chain = column.footerChain
        tokens = chain.tokenKeys.map({ (key: TokenKey) in citadel.anyToken(key: key) })
        let (lambda, lastMorphNo) = Parser.compile(tokens: tokens, tokenKey: chain.key, memory: tower.memory)
        if let lambda {
            if tower.variableToken.status == .invalid { tower.variableToken.status = .ok }
            if let lastMorphNo {
                let morph = Morph(rawValue: lastMorphNo)
                tower.variableToken.def = morph.def
            }
            else { tower.variableToken.def = RealDef.def }
            return lambda
        } else {
            if tower.variableToken.status == .ok { tower.variableToken.status = .invalid }
            return nil
        }
    }
    private func compileCNT() -> UnsafeMutablePointer<Lambda>? {
        let memory: UnsafeMutablePointer<Memory> = citadel.memory
        let vi: mnimi = AEMemoryIndexForName(memory, column.footerTokenKey.tag.toInt8())
        
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
            case .running:  return compileNON()
            case .match:    return compileMTC()
            case .count:    return compileCNT()
        }
    }
    func loadTokens() {
        guard let citadel else { return }
        tokens = column.footerChain.tokenKeys.map({ (key: TokenKey) in citadel.anyToken(key: key) })
    }

    // Core ========================================================================================
    override var key: TokenKey { column.footerTokenKey }
    override var valueDisplay: String { tower?.obje.display ?? "" }

//    override func createTower(_ citadel: Citadel) -> Tower { citadel.createTower(key: key, core: self) }
    override func buildUpstream(tower: Tower) {
        tower.citadel.nukeUpstream(key: column.footerTokenKey)
        switch column.aggregate {
            case .sum, .average, .count:
                for rowNo: Int in 1...column.grid.rows {
                    let cell: Cell = column.grid.cell(colNo: column.colNo, rowNo: rowNo)
                    let cellTower: Tower = tower.citadel.tower(key: cell.chain.key!)!
                    cellTower.attach(tower)
                }
            case .match:
                loadTokens()
                tokens.compactMap { $0 as? TowerToken }.forEach {
                    $0.tower.attach(tower)
                }
            case .none, .running:
                return
        }
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
        loadTokens()
        AEMemoryUnfix(tower.memory, tower.index)
    }
    override func executeTask(tower: Tower) {
        AETaskExecute(tower.task, tower.memory)
        AEMemoryFix(tower.memory, tower.index)
        tower.variableToken.def = tower.obje.def
    }    
}

//
//  Graph.swift
//  OoviumEngine
//
//  Created by Joe Charlier on 1/14/23.
//  Copyright © 2023 Aepryus Software. All rights reserved.
//

import Acheron
import Aegean
import Foundation

public class Graph: Aexel, TowerDelegate {
//    var name: String = ""
    public var fX: Chain = Chain()
    public var fY: Chain = Chain()
    public var fZ: Chain = Chain()
    public var sUChain: Chain = Chain()
    public var eUChain: Chain = Chain()
    public var dUChain: Chain = Chain()
    public var sVChain: Chain = Chain()
    public var eVChain: Chain = Chain()
    public var dVChain: Chain = Chain()
    public var system: Int = 0
    public var surfaceOn: Bool = true
    public var lightOn: Bool = true
    public var netOn: Bool = true
    public var surfaceColor: RGB = .white
    public var lightColor: RGB = .white
    public var netColor: RGB = .white
    public var backgroundColor: RGB = .black
    public var viewX: String = ""
    public var viewY: String = ""
    public var viewZ: String = ""
    public var lookOrigin: Bool = true
    public var lookX: String = ""
    public var lookY: String = ""
    public var lookZ: String = ""
    public var orientX: String = ""
    public var orientY: String = ""
    public var orientZ: String = ""
    public var lightX: String = ""
    public var lightY: String = ""
    public var lightZ: String = ""
    public var tChain: Chain = Chain()
    
    //    private R3toR3 function;
    //
    public var sU: Double = 0
    public var eU: Double = 0
    public var dU: Double = 0
    public var sV: Double = 0
    public var eV: Double = 0
    public var dV: Double = 0
    public var sT: Double = 0
    public var eT: Double = 0
    
    public var t: Double = 0

    public var view: V3 = .zero
    public var look: V3 = .zero
    public var orient: V3 = .zero
    public var light: V3 = .zero
    
    public var xAxis: V3 = .zero
    public var yAxis: V3 = .zero
    public var zAxis: V3 = .zero

//    var x: Int
//    var y: Int
    public var width: Int = 0
    public var height: Int = 0
    public var center: CGPoint = .zero
    public var lens: Double = 0

    public var nU: Int = 0
    public var nV: Int = 0
    
//    var vertices: [Vertex] = []
//    var tiles: [Tile] = []
    
    var web: AnyObject { self }

    public var xRecipe: UnsafeMutablePointer<Recipe>? = nil
    public var yRecipe: UnsafeMutablePointer<Recipe>? = nil
    public var zRecipe: UnsafeMutablePointer<Recipe>? = nil
    
    private var uTokenDelegate = StaticVariableTokenDelegate("u")
    private var vTokenDelegate = StaticVariableTokenDelegate("v")
    private var tTokenDelegate = StaticVariableTokenDelegate("t")

    lazy public var uTower: Tower = aether.createTower(tag: "\(key).u", towerDelegate: self, tokenDelegate: uTokenDelegate)
    lazy public var vTower: Tower = aether.createTower(tag: "\(key).v", towerDelegate: self, tokenDelegate: vTokenDelegate)
    lazy public var tTower: Tower = aether.createTower(tag: "\(key).t", towerDelegate: self, tokenDelegate: tTokenDelegate)
    
    public func compileRecipes() {
        let memory: UnsafeMutablePointer<Memory> = AEMemoryCreateClone(aether.memory)
        AEMemoryClear(memory)
        
        AEMemorySetValue(memory, uTower.index, 0)
        AEMemorySetValue(memory, vTower.index, 0)
        AEMemorySetValue(memory, tTower.index, 0)
        
        xRecipe = Math.compile(result: fX.tower, memory: memory)
        yRecipe = Math.compile(result: fY.tower, memory: memory)
        zRecipe = Math.compile(result: fZ.tower, memory: memory)

        AERecipeSignature(xRecipe, AEMemoryIndexForName(memory, "\(key).x".toInt8()), UInt8(3))
        AERecipeSignature(yRecipe, AEMemoryIndexForName(memory, "\(key).y".toInt8()), UInt8(3))
        AERecipeSignature(zRecipe, AEMemoryIndexForName(memory, "\(key).z".toInt8()), UInt8(3))

        let uIndex = AEMemoryIndexForName(memory, "\(key).u".toInt8())
        let vIndex = AEMemoryIndexForName(memory, "\(key).v".toInt8())
        let tIndex = AEMemoryIndexForName(memory, "\(key).t".toInt8())

        xRecipe?.pointee.params[0] = uIndex
        xRecipe?.pointee.params[1] = vIndex
        xRecipe?.pointee.params[2] = tIndex
        
        yRecipe?.pointee.params[0] = uIndex
        yRecipe?.pointee.params[1] = vIndex
        yRecipe?.pointee.params[2] = tIndex

        zRecipe?.pointee.params[0] = uIndex
        zRecipe?.pointee.params[1] = vIndex
        zRecipe?.pointee.params[2] = tIndex
        
//        var towers: Set<Tower> = xTower.towersDestinedFor()
//        towers.forEach { AEMemoryMarkLoaded(memory, $0.index) }
//
//        var index: mnimi = AEMemoryIndexForName(memory, xTower.variableToken.tag.toInt8())
//        AEMemorySet(memory, index, AEObjRecipe(xRecipe))
//        AEMemoryFix(memory, index)
//
//        towers = yResultTower.towersDestinedFor()
//        towers.forEach { AEMemoryMarkLoaded(memory, $0.index) }
//
//        index = AEMemoryIndexForName(memory, yTower.variableToken.tag.toInt8())
//        AEMemorySet(memory, index, AEObjRecipe(yRecipe))
//        AEMemoryFix(memory, index)
//
//        towers = zResultTower.towersDestinedFor()
//        towers.forEach { AEMemoryMarkLoaded(memory, $0.index) }
//
//        index = AEMemoryIndexForName(memory, zTower.variableToken.tag.toInt8())
//        AEMemorySet(memory, index, AEObjRecipe(zRecipe))
//        AEMemoryFix(memory, index)
//
//        AERecipeSetMemory(xRecipe, memory)
//        AERecipeSetMemory(yRecipe, memory)
//        AERecipeSetMemory(zRecipe, memory)
    }

// Events ==========================================================================================
    override public func onLoad() {
        uTower.web = web
        vTower.web = web
        tTower.web = web
        
        sUChain.tower = aether.createTower(tag: "\(key).sU", towerDelegate: sUChain)
        eUChain.tower = aether.createTower(tag: "\(key).eU", towerDelegate: eUChain)
        dUChain.tower = aether.createTower(tag: "\(key).dU", towerDelegate: dUChain)
        sVChain.tower = aether.createTower(tag: "\(key).sV", towerDelegate: sVChain)
        eVChain.tower = aether.createTower(tag: "\(key).eV", towerDelegate: eVChain)
        dVChain.tower = aether.createTower(tag: "\(key).dV", towerDelegate: dVChain)

        tChain.tower = aether.createTower(tag: "\(key).time", towerDelegate: tChain)
        
        fX.tower = aether.createTower(tag: "\(key).x", towerDelegate: fX)
        fY.tower = aether.createTower(tag: "\(key).y", towerDelegate: fY)
        fZ.tower = aether.createTower(tag: "\(key).z", towerDelegate: fZ)
        
        name = "Waves"
        sU = -4
        eU = 4
        dU = 8/40
        sV = -4
        eV = 4
        dV = 8/40
        view = V3(8.91167255619427, 8.2567481154179, 9.63093990157929)
        look = V3(-0.597824245607881, -0.542194458806552, -0.704535868587812)
        orient = V3(-0.821996365745422, 0.445722968116547, 0.35447568378478912120)
        light = V3(1, 21, 20)
        surfaceColor = RGB(r: 49, g: 49, b: 100)
        lightColor = RGB(r: 172, g: 172, b: 215)
        netColor = RGB(r: 255, g: 255, b: 255)
        
        sUChain.post(token: .neg)
        sUChain.post(token: .four)
        
        eUChain.post(token: .four)
        
        dUChain.post(token: .four)
        dUChain.post(token: .zero)
        
        sVChain.post(token: .neg)
        sVChain.post(token: .four)
        
        eVChain.post(token: .four)
        
        dVChain.post(token: .four)
        dVChain.post(token: .zero)
        
        fX.post(token: uTower.variableToken)
        fY.post(token: vTower.variableToken)
        fZ.post(token: .sin)
        fZ.post(token: uTower.variableToken)
        fZ.post(token: .multiply)
        fZ.post(token: vTower.variableToken)
        fZ.post(token: .add)
        fZ.post(token: tTower.variableToken)
        fZ.post(token: .rightParen)
        fZ.post(token: .divide)
        fZ.post(token: .three)
    }

// Aexel ===========================================================================================
    public override var code: String { "Gp" }
    public override var towers: Set<Tower> { Set<Tower>([uTower, vTower, tTower, fX.tower, fY.tower, fZ.tower]) }

// Domain ==========================================================================================
    override public var properties: [String] { super.properties + [] }

// TowerDelegate ===================================================================================
    func buildUpstream(tower: Tower) {
//        xResultTower.attach(xTower)
//        yResultTower.attach(yTower)
//        zResultTower.attach(zTower)
    }
    func renderDisplay(tower: Tower) -> String {
        if tower.variableToken.status == .deleted { fatalError() }
        if tower.variableToken.status == .invalid { return "INVALID" }
        if tower.variableToken.status == .blocked { return "BLOCKED" }
        return name
    }
//    func buildWorker(tower: Tower) {}
    func workerCompleted(tower: Tower, askedBy: Tower) -> Bool {
        true
//        AEMemoryLoaded(tower.memory, AEMemoryIndexForName(aether.memory, variableToken.tag.toInt8())) != 0 || (askedBy !== tower && askedBy.web === self)
    }
    func workerBlocked(tower: Tower) -> Bool { tower.variableToken.status != .ok }
    func resetWorker(tower: Tower) {
//        recipe = nil
//        AEMemoryUnfix(tower.memory, AEMemoryIndexForName(aether.memory, tower.variableToken.tag.toInt8()))
    }
    func executeWorker(tower: Tower) {
//        compileRecipe()
//        AEMemorySet(tower.memory, AEMemoryIndexForName(aether.memory, tower.variableToken.tag.toInt8()), AEObjRecipe(recipe))
        AEMemoryFix(tower.memory, AEMemoryIndexForName(aether.memory, tower.variableToken.tag.toInt8()))
        tower.variableToken.def = RecipeDef.def
    }
}

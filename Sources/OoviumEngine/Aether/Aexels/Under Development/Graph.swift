//
//  Graph.swift
//  OoviumEngine
//
//  Created by Joe Charlier on 1/14/23.
//  Copyright © 2023 Aepryus Software. All rights reserved.
//

/*
 *  Graph is the creating visual representations of data in 2D, 3D and 4D.  It makes use of
 *  AepGraph's renderer.  It works in conjunction with Coordinate and Cron to replicate all the
 *  functionality of AepGraph.
 */


#if canImport(UIKit)

import Acheron
import Aegean
import Foundation

public class Graph: Aexel, TowerDelegate, Web {
    @objc public var fXChain: Chain!
    @objc public var fYChain: Chain!
    @objc public var fZChain: Chain!
    @objc public var sUChain: Chain!
    @objc public var eUChain: Chain!
    @objc public var dUChain: Chain!
    @objc public var sVChain: Chain!
    @objc public var eVChain: Chain!
    @objc public var dVChain: Chain!
    @objc public var tChain: Chain!
    @objc public var coordinateNo: Int = 0
    
    public var coordinate: Coordinate? = nil
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
    
    var web: Web { self }

    public var xRecipe: UnsafeMutablePointer<Recipe>? = nil
    public var yRecipe: UnsafeMutablePointer<Recipe>? = nil
    public var zRecipe: UnsafeMutablePointer<Recipe>? = nil
    
    private var uTokenDelegate = StaticVariableTokenDelegate("u")
    private var vTokenDelegate = StaticVariableTokenDelegate("v")
    private var tTokenDelegate = StaticVariableTokenDelegate("t")

//    lazy public var uTower: Tower = aether.state.createTower(tag: "\(key).u", towerDelegate: self, tokenDelegate: uTokenDelegate)
//    lazy public var vTower: Tower = aether.state.createTower(tag: "\(key).v", towerDelegate: self, tokenDelegate: vTokenDelegate)
//    lazy public var tTower: Tower = aether.state.createTower(tag: "\(key).t", towerDelegate: self, tokenDelegate: tTokenDelegate)
    
    public func compileRecipes() {
//        let memory: UnsafeMutablePointer<Memory> = AEMemoryCreateClone(aether.state.memory)
//        AEMemoryClear(memory)
//        
//        AEMemorySetValue(memory, uTower.index, 0)
//        AEMemorySetValue(memory, vTower.index, 0)
//        AEMemorySetValue(memory, tTower.index, 0)
//        
//        xRecipe = Math.compile(result: fXChain.tower, memory: memory)
//        yRecipe = Math.compile(result: fYChain.tower, memory: memory)
//        zRecipe = Math.compile(result: fZChain.tower, memory: memory)
//
//        AERecipeSignature(xRecipe, AEMemoryIndexForName(memory, "\(key).x".toInt8()), UInt8(3))
//        AERecipeSignature(yRecipe, AEMemoryIndexForName(memory, "\(key).y".toInt8()), UInt8(3))
//        AERecipeSignature(zRecipe, AEMemoryIndexForName(memory, "\(key).z".toInt8()), UInt8(3))
//
//        let uIndex = AEMemoryIndexForName(memory, "\(key).u".toInt8())
//        let vIndex = AEMemoryIndexForName(memory, "\(key).v".toInt8())
//        let tIndex = AEMemoryIndexForName(memory, "\(key).t".toInt8())
//
//        xRecipe?.pointee.params[0] = uIndex
//        xRecipe?.pointee.params[1] = vIndex
//        xRecipe?.pointee.params[2] = tIndex
//        
//        yRecipe?.pointee.params[0] = uIndex
//        yRecipe?.pointee.params[1] = vIndex
//        yRecipe?.pointee.params[2] = tIndex
//
//        zRecipe?.pointee.params[0] = uIndex
//        zRecipe?.pointee.params[1] = vIndex
//        zRecipe?.pointee.params[2] = tIndex
    }

// Events ==========================================================================================
    override public func onLoad() {
//        uTower.web = web
//        vTower.web = web
//        tTower.web = web
        
//        sUChain.tower = aether.state.createTower(tag: "\(key).sU", towerDelegate: sUChain)
//        eUChain.tower = aether.state.createTower(tag: "\(key).eU", towerDelegate: eUChain)
//        dUChain.tower = aether.state.createTower(tag: "\(key).dU", towerDelegate: dUChain)
//        sVChain.tower = aether.state.createTower(tag: "\(key).sV", towerDelegate: sVChain)
//        eVChain.tower = aether.state.createTower(tag: "\(key).eV", towerDelegate: eVChain)
//        dVChain.tower = aether.state.createTower(tag: "\(key).dV", towerDelegate: dVChain)
//
//        tChain.tower = aether.state.createTower(tag: "\(key).time", towerDelegate: tChain)
//        
//        fXChain.tower = aether.state.createTower(tag: "\(key).x", towerDelegate: fXChain)
//        fYChain.tower = aether.state.createTower(tag: "\(key).y", towerDelegate: fYChain)
//        fZChain.tower = aether.state.createTower(tag: "\(key).z", towerDelegate: fZChain)
        
//        fXChain.tower.tailForWeb = web
//        fYChain.tower.tailForWeb = web
//        fZChain.tower.tailForWeb = web

        view = V3(8.91167255619427, 8.2567481154179, 9.63093990157929)
        look = V3(-0.597824245607881, -0.542194458806552, -0.704535868587812)
        orient = V3(-0.821996365745422, 0.445722968116547, 0.35447568378478912120)
        light = V3(1, 21, 20)
        surfaceColor = RGB(r: 49, g: 49, b: 100)
        lightColor = RGB(r: 172, g: 172, b: 215)
        netColor = RGB(r: 255, g: 255, b: 255)
        
        coordinate = aether.aexel(no: coordinateNo)
    }

// Aexel ===========================================================================================
    public override var code: String { "Gp" }
//    public var towers: Set<Tower> { Set<Tower>([
//        uTower, vTower, tTower,
//        fXChain.tower, fYChain.tower, fZChain.tower,
//        sUChain.tower, eUChain.tower, dUChain.tower,
//        sVChain.tower, eVChain.tower, dVChain.tower,
//        tChain.tower
//    ]) }

// Domain ==========================================================================================
    override public var properties: [String] { super.properties + [
        "fXChain", "fYChain", "fZChain", "sUChain", "eUChain", "dUChain",
        "sVChain", "eVChain", "dVChain", "tChain", "coordinateNo"
    ] }

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
//    func renderTask(tower: Tower) -> UnsafeMutablePointer<Task>? { nil }
    func taskCompleted(tower: Tower, askedBy: Tower) -> Bool {
        true
//        AEMemoryLoaded(tower.memory, AEMemoryIndexForName(aether.memory, variableToken.tag.toInt8())) != 0 || (askedBy !== tower && askedBy.web === self)
    }
    func taskBlocked(tower: Tower) -> Bool { tower.variableToken.status != .ok }
    func resetTask(tower: Tower) {
//        recipe = nil
//        AEMemoryUnfix(tower.memory, AEMemoryIndexForName(aether.memory, tower.variableToken.tag.toInt8()))
    }
    func executeTask(tower: Tower) {
//        compileRecipe()
//        AEMemorySet(tower.memory, AEMemoryIndexForName(aether.memory, tower.variableToken.tag.toInt8()), AEObjRecipe(recipe))
//        AEMemoryFix(tower.memory, AEMemoryIndexForName(aether.state.memory, tower.variableToken.tag.toInt8()))
        tower.variableToken.def = RecipeDef.def
    }
}

#endif

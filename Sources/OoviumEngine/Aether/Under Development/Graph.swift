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

class GraphRecipeDelegate: RecipeDelegate {
    enum Dimension { case x, y, z }
    
    let graph: Graph
    let dimension: Dimension
    
    init(graph: Graph, dimension: Dimension) {
        self.graph = graph
        self.dimension = dimension
    }

// RecipeDelegate ==================================================================================
    var name: String { "\(graph.name).\(dimension)" }
    var variableTokenKey: TokenKey {
        switch dimension {
            case .x: return graph.xVariableTokenKey
            case .y: return graph.yVariableTokenKey
            case .z: return graph.zVariableTokenKey
        }
    }
    var mechlikeTokenKey: TokenKey {
        switch dimension {
            case .x: return graph.xMechlikeTokenKey
            case .y: return graph.yMechlikeTokenKey
            case .z: return graph.zMechlikeTokenKey
        }
    }
    var params: [TokenKey] { [
        graph.uTokenKey,
        graph.vTokenKey,
        graph.tTokenKey
    ] }
    var resultChain: Chain {
        switch dimension {
            case .x: return graph.fXChain
            case .y: return graph.fYChain
            case .z: return graph.fZChain
        }
    }
    
// VariableTokenDelegate ===========================================================================
    var alias: String?
}

public class Graph: Aexel {
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
    
    public var fXTokenKey: TokenKey { TokenKey(code: .va, tag: "\(key).fX") }
    public var fYTokenKey: TokenKey { TokenKey(code: .va, tag: "\(key).fY") }
    public var fZTokenKey: TokenKey { TokenKey(code: .va, tag: "\(key).fZ") }
    public var sUTokenKey: TokenKey { TokenKey(code: .va, tag: "\(key).sU") }
    public var eUTokenKey: TokenKey { TokenKey(code: .va, tag: "\(key).eU") }
    public var dUTokenKey: TokenKey { TokenKey(code: .va, tag: "\(key).dU") }
    public var sVTokenKey: TokenKey { TokenKey(code: .va, tag: "\(key).sV") }
    public var eVTokenKey: TokenKey { TokenKey(code: .va, tag: "\(key).eV") }
    public var dVTokenKey: TokenKey { TokenKey(code: .va, tag: "\(key).dV") }
    public var uTokenKey: TokenKey { TokenKey(code: .va, tag: "\(key).u") }
    public var vTokenKey: TokenKey { TokenKey(code: .va, tag: "\(key).v") }
    public var tTokenKey: TokenKey { TokenKey(code: .va, tag: "\(key).t") }
    
    public var xVariableTokenKey: TokenKey { TokenKey(code: .va, tag: "\(key).x") }
    public var xMechlikeTokenKey: TokenKey { TokenKey(code: .ml, tag: "\(key).x") }
    
    public var yVariableTokenKey: TokenKey { TokenKey(code: .va, tag: "\(key).y") }
    public var yMechlikeTokenKey: TokenKey { TokenKey(code: .ml, tag: "\(key).y") }
    
    public var zVariableTokenKey: TokenKey { TokenKey(code: .va, tag: "\(key).z") }
    public var zMechlikeTokenKey: TokenKey { TokenKey(code: .ml, tag: "\(key).z") }

    public var coordinate: Coordinate? = nil
    public var surfaceOn: Bool = true
//    public var lightOn: Bool = true
//    public var netOn: Bool = true
    public var surfaceColor: RGB = .white
    public var lightColor: RGB = .white
    public var netColor: RGB = .white
//    public var backgroundColor: RGB = .black
//    public var viewX: String = ""
//    public var viewY: String = ""
//    public var viewZ: String = ""
//    public var lookOrigin: Bool = true
//    public var lookX: String = ""
//    public var lookY: String = ""
//    public var lookZ: String = ""
//    public var orientX: String = ""
//    public var orientY: String = ""
//    public var orientZ: String = ""
//    public var lightX: String = ""
//    public var lightY: String = ""
//    public var lightZ: String = ""
    
    public var sU: Double = 0
    public var eU: Double = 0
    public var dU: Double = 0
    public var sV: Double = 0
    public var eV: Double = 0
    public var dV: Double = 0
//    public var sT: Double = 0
//    public var eT: Double = 0
    
    public var t: Double = 0

    public var view: V3 = .zero
    public var look: V3 = .zero
    public var orient: V3 = .zero
    public var light: V3 = .zero
    
    public var xAxis: V3 = .zero
    public var yAxis: V3 = .zero
    public var zAxis: V3 = .zero

//    public var width: Int = 0
//    public var height: Int = 0
    public var center: CGPoint = .zero
    public var lens: Double = 0

    public var nU: Int = 0
    public var nV: Int = 0
    
// Aexon ===========================================================================================
    public override var code: String { "Gp" }
    public override var tokenKeys: [TokenKey] { [
        fXTokenKey, fYTokenKey, fZTokenKey,
        sUTokenKey, eUTokenKey, dUTokenKey,
        sVTokenKey, eVTokenKey, dVTokenKey,
        uTokenKey, vTokenKey, tTokenKey,
        xVariableTokenKey, yVariableTokenKey, zVariableTokenKey,
        xMechlikeTokenKey, yMechlikeTokenKey, zMechlikeTokenKey
    ] }
    public override func createCores() -> [Core] { [
        ChainCore(chain: fXChain), ChainCore(chain: fYChain), ChainCore(chain: fZChain),
        ChainCore(chain: sUChain), ChainCore(chain: eUChain), ChainCore(chain: dUChain),
        ChainCore(chain: sVChain), ChainCore(chain: eVChain), ChainCore(chain: dVChain),
        
        ParameterCore(parameter: StaticParameter(tokenKey: uTokenKey, fogKey: xMechlikeTokenKey, name: "u")),
        ParameterCore(parameter: StaticParameter(tokenKey: vTokenKey, fogKey: xMechlikeTokenKey, name: "v")),
        ParameterCore(parameter: StaticParameter(tokenKey: tTokenKey, fogKey: xMechlikeTokenKey, name: "t")),
        
        ParameterCore(parameter: StaticParameter(tokenKey: uTokenKey, fogKey: yMechlikeTokenKey, name: "u")),
        ParameterCore(parameter: StaticParameter(tokenKey: vTokenKey, fogKey: yMechlikeTokenKey, name: "v")),
        ParameterCore(parameter: StaticParameter(tokenKey: tTokenKey, fogKey: yMechlikeTokenKey, name: "t")),

        ParameterCore(parameter: StaticParameter(tokenKey: uTokenKey, fogKey: zMechlikeTokenKey, name: "u")),
        ParameterCore(parameter: StaticParameter(tokenKey: vTokenKey, fogKey: zMechlikeTokenKey, name: "v")),
        ParameterCore(parameter: StaticParameter(tokenKey: tTokenKey, fogKey: zMechlikeTokenKey, name: "t")),
//        ChainCore(chain: tChain),
        RecipeCore(delegate: GraphRecipeDelegate(graph: self, dimension: .x)),
        RecipeCore(delegate: GraphRecipeDelegate(graph: self, dimension: .y)),
        RecipeCore(delegate: GraphRecipeDelegate(graph: self, dimension: .z))
    ] }
    public override var chains: [Chain] { [
        fXChain, fYChain, fZChain,
        sUChain, eUChain, dUChain,
        sVChain, eVChain, dVChain,
        tChain
    ] }

// Domain ==========================================================================================
    public override var properties: [String] { super.properties + [
        "sUChain", "eUChain", "dUChain", "sVChain", "eVChain", "dVChain", "tChain", "coordinateNo",
        "fXChain", "fYChain", "fZChain"
    ] }
}

#endif

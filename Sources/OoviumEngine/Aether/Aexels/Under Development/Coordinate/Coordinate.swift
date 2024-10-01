//
//  Coordinate.swift
//  OoviumEngine
//
//  Created by Joe Charlier on 1/14/23.
//  Copyright © 2023 Aepryus Software. All rights reserved.
//

/*
 *  Coordinate is for creating different coordinate systems that can be used with
 *  Graph in order to render plots; e.g., Cartesian, Polar, Cylindrical and Sphrerical.
 *  Coordinate is the main Aexel.  Dimension are its dimensions (x,y,z) and Transform
 *  are the chains defining the transformations to and from Cartesian.
 */

import Foundation

public class Coordinate: Aexel {
    @objc lazy public var toCart: Transform = Transform(aexel: self, name: "to")
    @objc lazy public var fromCart: Transform = Transform(aexel: self, name: "from")
    
    public func compileRecipes() {
        toCart.compileRecipes()
        fromCart.compileRecipes()
    }
    
// Aexel ===========================================================================================
//    public var towers: Set<Tower> {
//        var towers = Set<Tower>()
//        toCart.towers.forEach { towers.insert($0) }
//        fromCart.towers.forEach { towers.insert($0) }
//        return towers
//    }
    
// Aexon ===========================================================================================
    public override var code: String { "Cd" }

// Domain ==========================================================================================
    public override var properties: [String] { super.properties + ["toCart", "fromCart"] }
}

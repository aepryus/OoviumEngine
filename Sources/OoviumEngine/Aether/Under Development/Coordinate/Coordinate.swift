//
//  Coordinate.swift
//  OoviumEngine
//
//  Created by Joe Charlier on 1/14/23.
//  Copyright © 2023 Aepryus Software. All rights reserved.
//

/*
 *  Coordinate is for creating different coordinate systems that can be used with
 *  Graph in order to render plots; e.g., Cartesian, Polar, Cylindrical and Spherical.
 *  Coordinate is the main Aexel.  Dimension are its dimensions (x,y,z) and Transform
 *  are the chains defining the transformations to and from Cartesian.
 */

import Foundation

public class Coordinate: Aexel {
    @objc lazy public var toCart: Transform = Transform(aexel: self, name: "to")
    @objc lazy public var fromCart: Transform = Transform(aexel: self, name: "from")

// Aexon ===========================================================================================
    public override var code: String { "Cd" }

    public override var tokenKeys: [TokenKey] {
        toCart.tokenKeys + fromCart.tokenKeys
    }
    public override func createCores() -> [Core] {
        toCart.createCores() + fromCart.createCores()
    }
    public override var chains: [Chain] {
        toCart.dimensions.compactMap { $0.chain } + fromCart.dimensions.compactMap { $0.chain }
    }

// Domain ==========================================================================================
    public override var properties: [String] { super.properties + ["toCart", "fromCart"] }

// Factories =======================================================================================
    @discardableResult
    public static func cartesian(in aether: Aether) -> Coordinate {
        let coordinate: Coordinate = aether.create(at: .zero)
        coordinate.name = "Cartesian"
        configure(coordinate: coordinate,
                  inputs: ["x", "y", "z"],
                  toCart: ["x", "y", "z"].map { tag in "va:\(coordinate.key).to.\(tag)" },
                  fromCart: ["x", "y", "z"].map { tag in "va:\(coordinate.key).from.\(tag)" })
        return coordinate
    }

    @discardableResult
    public static func cylindrical(in aether: Aether) -> Coordinate {
        let coordinate: Coordinate = aether.create(at: .zero)
        coordinate.name = "Cylindrical"
        let k: String = coordinate.key
        configure(coordinate: coordinate,
                  inputs: ["ρ", "ϕ", "z"],
                  toCart: [
                    "va:\(k).to.ρ;op:×;fn:cos;va:\(k).to.ϕ;sp:)",
                    "va:\(k).to.ρ;op:×;fn:sin;va:\(k).to.ϕ;sp:)",
                    "va:\(k).to.z"
                  ],
                  fromCart: [
                    "fn:sqrt;va:\(k).from.x;op:^;dg:2;op:+;va:\(k).from.y;op:^;dg:2;sp:)",
                    "fn:atan2;va:\(k).from.y;sp:,;va:\(k).from.x;sp:)",
                    "va:\(k).from.z"
                  ])
        return coordinate
    }

    @discardableResult
    public static func spherical(in aether: Aether) -> Coordinate {
        let coordinate: Coordinate = aether.create(at: .zero)
        coordinate.name = "Spherical"
        let k: String = coordinate.key
        configure(coordinate: coordinate,
                  inputs: ["θ", "ϕ", "r"],
                  toCart: [
                    "va:\(k).to.r;op:×;fn:sin;va:\(k).to.θ;sp:);op:×;fn:cos;va:\(k).to.ϕ;sp:)",
                    "va:\(k).to.r;op:×;fn:sin;va:\(k).to.θ;sp:);op:×;fn:sin;va:\(k).to.ϕ;sp:)",
                    "va:\(k).to.r;op:×;fn:cos;va:\(k).to.θ;sp:)"
                  ],
                  fromCart: [
                    "fn:acos;va:\(k).from.z;op:÷;fn:sqrt;va:\(k).from.x;op:^;dg:2;op:+;va:\(k).from.y;op:^;dg:2;op:+;va:\(k).from.z;op:^;dg:2;sp:);sp:)",
                    "fn:atan2;va:\(k).from.y;sp:,;va:\(k).from.x;sp:)",
                    "fn:sqrt;va:\(k).from.x;op:^;dg:2;op:+;va:\(k).from.y;op:^;dg:2;op:+;va:\(k).from.z;op:^;dg:2;sp:)"
                  ])
        return coordinate
    }

    private static func configure(coordinate: Coordinate, inputs: [String], toCart: [String], fromCart: [String]) {
        let toDims: [Dimension] = inputs.enumerated().map { (i, name) in
            let dim: Dimension = Dimension(web: coordinate.toCart, name: name)
            dim.chain = Chain("va:\(coordinate.key).to.f\(i)::\(toCart[i])")
            return dim
        }
        coordinate.toCart.dimensions = toDims

        let fromInputs: [String] = ["x", "y", "z"]
        let fromDims: [Dimension] = fromInputs.enumerated().map { (i, name) in
            let dim: Dimension = Dimension(web: coordinate.fromCart, name: name)
            dim.chain = Chain("va:\(coordinate.key).from.f\(i)::\(fromCart[i])")
            return dim
        }
        coordinate.fromCart.dimensions = fromDims
    }
}

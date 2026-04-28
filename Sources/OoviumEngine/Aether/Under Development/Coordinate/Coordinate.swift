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
        // Inputs in (h, theta, r) order so graph.fX/fY/fZ map naturally to (h, theta, r).
        // toCart: x = r·cos(theta), y = r·sin(theta), z = h.
        configure(coordinate: coordinate,
                  inputs: ["h", "theta", "r"],
                  toCart: [
                    "va:\(k).to.r;op:×;fn:cos;va:\(k).to.theta;sp:)",
                    "va:\(k).to.r;op:×;fn:sin;va:\(k).to.theta;sp:)",
                    "va:\(k).to.h"
                  ],
                  fromCart: [
                    "va:\(k).from.x",
                    "va:\(k).from.y",
                    "va:\(k).from.z"
                  ])
        return coordinate
    }

    @discardableResult
    public static func spherical(in aether: Aether) -> Coordinate {
        let coordinate: Coordinate = aether.create(at: .zero)
        coordinate.name = "Spherical"
        let k: String = coordinate.key
        // ASCII parameter names; non-ASCII tags (θ/ϕ) don't round-trip reliably through
        // the C-string token-tag plumbing.
        configure(coordinate: coordinate,
                  inputs: ["theta", "phi", "r"],
                  toCart: [
                    "va:\(k).to.r;op:×;fn:sin;va:\(k).to.theta;sp:);op:×;fn:cos;va:\(k).to.phi;sp:)",
                    "va:\(k).to.r;op:×;fn:sin;va:\(k).to.theta;sp:);op:×;fn:sin;va:\(k).to.phi;sp:)",
                    "va:\(k).to.r;op:×;fn:cos;va:\(k).to.theta;sp:)"
                  ],
                  fromCart: [
                    "va:\(k).from.x",
                    "va:\(k).from.y",
                    "va:\(k).from.z"
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

//
//  Coordinate.swift
//  OoviumEngine
//
//  Created by Joe Charlier on 1/14/23.
//  Copyright © 2023 Aepryus Software. All rights reserved.
//

import Foundation

public class Coordinate: Aexel {
    @objc lazy public var toCart: Web = Web(aexel: self, name: "to")
    @objc lazy public var fromCart: Web = Web(aexel: self, name: "from")

// Aexel ===========================================================================================
    public override var code: String { "Cd" }
    public override var towers: Set<Tower> {
        var towers = Set<Tower>()
        toCart.towers.forEach { towers.insert($0) }
        fromCart.towers.forEach { towers.insert($0) }
        return towers
    }

// Domain ==========================================================================================
    override public var properties: [String] { super.properties + ["toCart", "fromCart"] }
}

//
//  Coordinate.swift
//  OoviumEngine
//
//  Created by Joe Charlier on 1/14/23.
//  Copyright © 2023 Aepryus Software. All rights reserved.
//

import Acheron
import Foundation

public class Dimension: Domain {
    @objc public var name: String = ""
    @objc public var toCart: Chain!
    @objc public var fromCart: Chain!
    
// Domain ==========================================================================================
    override public var properties: [String] { super.properties + ["name", "toCart", "fromCart"] }
}

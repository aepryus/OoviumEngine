//
//  Coordinate.swift
//  OoviumEngine
//
//  Created by Joe Charlier on 1/14/23.
//  Copyright © 2023 Aepryus Software. All rights reserved.
//

import Foundation

public class Coordinate: Aexel {
    @objc public var dimensions: [Dimension] = []

// Aexel ===========================================================================================
    
// Domain ==========================================================================================
    override public var properties: [String] { super.properties + ["dimensions"] }
}

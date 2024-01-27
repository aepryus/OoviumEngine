//
//  System.swift
//  OoviumEngine
//
//  Created by Joe Charlier on 1/10/23.
//  Copyright © 2023 Aepryus Software. All rights reserved.
//

import Foundation

public class System: Aexel {
    @objc public var constants: [SystemValue] = []
    @objc public var variables: [SystemValue] = []

// Domain ==========================================================================================
//    override public var properties: [String] { super.properties + [] }
    override public var children: [String] { super.children + ["constants", "variables"] }
}

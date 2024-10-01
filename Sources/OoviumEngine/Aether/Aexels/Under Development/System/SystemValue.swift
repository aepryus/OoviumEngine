//
//  SystemValue.swift
//  OoviumEngine
//
//  Created by Joe Charlier on 1/11/23.
//  Copyright © 2023 Aepryus Software. All rights reserved.
//

import Acheron
import Foundation

public class SystemValue: Aexon {
    @objc public var name: String = ""
    
// Domain ==========================================================================================
    public override var properties: [String] { super.properties + ["name"] }
}

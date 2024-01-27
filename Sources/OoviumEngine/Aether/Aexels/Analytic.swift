//
//  Analytic.swift
//  OoviumEngine
//
//  Created by Joe Charlier on 1/12/23.
//  Copyright © 2023 Aepryus Software. All rights reserved.
//

import Acheron
import Foundation

public class Analytic: Aexel, VariableTokenDelegate {
    @objc public var anain: Anain = Anain()
    @objc public var label: String = ""

    public var token: VariableToken { anain.tower.variableToken }

// Events ==========================================================================================
    override public func onLoad() {
        anain.tower = aether.createTower(tag: key, towerDelegate: anain, tokenDelegate: self)
    }
    
// Aexel ===========================================================================================
    public override var code: String { "An" }
    public override var towers: Set<Tower> { Set<Tower>([]) }
    
// Domain ==========================================================================================
    override public var properties: [String] { super.properties + ["label"] }
    
// VariableTokenDelegate ===========================================================================
    public var alias: String? { label.count > 0 ? label : nil }
}

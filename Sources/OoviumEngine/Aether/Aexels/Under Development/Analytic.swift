//
//  Analytic.swift
//  OoviumEngine
//
//  Created by Joe Charlier on 1/12/23.
//  Copyright © 2023 Aepryus Software. All rights reserved.
//

/*
 *  Analytic is a bubble type for inputing and working with Analytic functions which will make use
 *  of OoviumEngine's new analytic engine.
 */

import Acheron
import Foundation

public class Analytic: Aexel, VariableTokenDelegate {
    @objc public var anain: Anain = Anain()
    @objc public var label: String = ""

    public var token: VariableToken { anain.tower.variableToken }

// Events ==========================================================================================
    public override func onLoad() {
//        anain.tower = aether.state.createTower(tag: key, towerDelegate: anain, tokenDelegate: self)
    }
    
// Aexel ===========================================================================================
    public override var code: String { "An" }
    public var towers: Set<Tower> { Set<Tower>([]) }
    
// Domain ==========================================================================================
    public override var properties: [String] { super.properties + ["label"] }
    
// VariableTokenDelegate ===========================================================================
    public var alias: String? { label.count > 0 ? label : nil }
}

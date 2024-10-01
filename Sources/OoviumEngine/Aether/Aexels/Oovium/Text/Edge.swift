//
//  Edge.swift
//  Oovium
//
//  Created by Joe Charlier on 12/30/16.
//  Copyright © 2016 Aepryus Software. All rights reserved.
//

import Acheron
import Foundation

public class Edge: Aexon {
	@objc public var textNo: Int = 0
    
    init(parent: Text, child: Text) {
        textNo = child.no
        super.init(parent: parent)
    }
    public required init(attributes: [String : Any], parent: Domain? = nil) { super.init(attributes: attributes, parent: parent) }
	
	public var text: Text? { parent as? Text }
	public var other: Text? { text?.aether.aexel(no: textNo) }
	
// Domain ==========================================================================================
	public override var properties: [String] { super.properties + ["textNo"] }
}

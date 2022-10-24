//
//  Edge.swift
//  Oovium
//
//  Created by Joe Charlier on 12/30/16.
//  Copyright © 2016 Aepryus Software. All rights reserved.
//

import Acheron
import Foundation

public final class Edge: Domain {
	@objc public var textNo: Int = 0
	
	public var text: Text {
		return parent! as! Text
	}
	public var other: Text { text.aether.aexel(no: textNo)! }
	
// Domain ==========================================================================================
	public override var properties: [String] {
		return super.properties + ["textNo"]
	}
}

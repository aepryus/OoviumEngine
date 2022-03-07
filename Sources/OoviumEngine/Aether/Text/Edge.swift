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
	@objc var textNo: Int = 0
	
	var text: Text {
		return parent! as! Text
	}
	var other: Text {
		return text.aether.aexel(type: "text", no: textNo)! as! Text
	}
	
// Domain ==========================================================================================
	public override var properties: [String] {
		return super.properties + ["textNo"]
	}
}

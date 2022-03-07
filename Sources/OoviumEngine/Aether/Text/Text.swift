//
//  Text.swift
//  Oovium
//
//  Created by Joe Charlier on 12/30/16.
//  Copyright © 2016 Aepryus Software. All rights reserved.
//

import Acheron
import Foundation

public final class Text: Aexel, NSCopying {
	@objc var color: OOColor = .orange
	@objc var shape: OOShape = .ellipse
	
	@objc public var edges: [Edge] = []
	
	public var outputEdges: [Edge] {
		return aether.outputEdges(for: self)
	}
	
	func edgeFor(text: Text) -> Edge? {
		for edge in edges {
			if edge.other === text {return edge}
		}
		return nil
	}
	func isLinkedTo(_ text: Text) -> Bool {
		let edge = edgeFor(text: text)
		return edge != nil
	}
	func linkTo(_ text: Text) {
		let edge = aether.createEdge(parent: self, child: text)
		edges.append(edge)
	}
	func unlinkTo(_ text: Text) {
		guard let edge = edgeFor(text: text) else {return}
		edges.remove(object: edge)
	}
	
//// Events ==========================================================================================
//	override public func onDelete() {
//		for edge in outputEdges {
//			edge.text.unlinkTo(self)
//		}
//	}
//
// Domain ==========================================================================================
	override public var properties: [String] {
		return super.properties + ["color", "shape"]
	}
	override public var children: [String] {
		return super.children + ["edges"]
	}
	
// NSCopying =======================================================================================
	public func copy(with zone: NSZone? = nil) -> Any {
		let attributes = unload()
		let copy = Text(attributes: attributes, parent: parent)
		copy.load(attributes: attributes)
		return copy
	}
}

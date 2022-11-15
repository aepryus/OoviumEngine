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
	@objc public var color: OOColor = .orange
	@objc public var shape: OOShape = .ellipse
	
	@objc public var edges: [Edge] = []
	
	public var outputEdges: [Edge] { aether.outputEdges(for: self) }
	
    public func edgeFor(text: Text) -> Edge? { edges.first { $0.textNo == text.no } }
	public func isLinkedTo(_ text: Text) -> Bool { edgeFor(text: text) != nil }
	public func linkTo(_ text: Text) {
        let edge: Edge = aether.createEdge(parent: self, child: text)
		edges.append(edge)
	}
	public func unlinkTo(_ text: Text) {
		guard let edge = edgeFor(text: text) else { return }
		edges.remove(object: edge)
	}
	
// Events ==========================================================================================
	override public func onDelete() {
        outputEdges.forEach { $0.text.unlinkTo(self) }
	}

// Domain ==========================================================================================
	override public var properties: [String] { super.properties + ["color", "shape"] }
	override public var children: [String] { super.children + ["edges"] }
	
// NSCopying =======================================================================================
	public func copy(with zone: NSZone? = nil) -> Any {
		let attributes = unload()
		let copy = Text(attributes: attributes, parent: parent)
		copy.load(attributes: attributes)
		return copy
	}
}

//
//  Text.swift
//  Oovium
//
//  Created by Joe Charlier on 12/30/16.
//  Copyright © 2016 Aepryus Software. All rights reserved.
//

import Acheron
import Foundation


public class Text: Aexel, NSCopying {
    @objc public enum Color: Int { case red, orange, yellow, lime, maroon, peach, paleYellow, olive, magenta, lavender, marine, green, violet, cyan, cobolt, blue, black, grey, white, clear, cgaRed, cgaLightRed, cgaBrown, cgaYellow, cgaGreen, cgaLightGreen, cgaCyan, cgaLightCyan, cgaBlue, cgaLightBlue, cgaMagenta, cgaLightMagenta }
    @objc public enum Shape: Int { case ellipse, rounded, rectangle, diamond }

    @objc public var color: Color = .orange
	@objc public var shape: Shape = .ellipse
	
	@objc public var edges: [Edge] = []
    
    public var tokenKey: TokenKey { TokenKey(code: .tx, tag: key) }
	
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
	public override func onDelete() {
        outputEdges.forEach { if let text = $0.text { text.unlinkTo(self) } }
	}
    
// Aexon ===========================================================================================
    public override var code: String { "Tx" }
    public override var tokenKeys: [TokenKey] { [tokenKey] }

// Domain ==========================================================================================
	public override var properties: [String] { super.properties + ["color", "shape"] }
	public override var children: [String] { super.children + ["edges"] }
	
// NSCopying =======================================================================================
	public func copy(with zone: NSZone? = nil) -> Any {
		let attributes = unload()
		let copy = Text(attributes: attributes, parent: parent)
		copy.load(attributes: attributes)
		return copy
	}
}

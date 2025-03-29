//
//  V2.swift
//  Oovium
//
//  Created by Joe Charlier on 2/18/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import Foundation

public struct V2 {
	public var x: Double
	public var y: Double
	
	public init(_ x: Double, _ y: Double) {
		self.x = x
		self.y = y
	}
	
	public func len() -> Double { sqrt(x*x+y*y) }
	
	public static func + (a: V2, b: V2) -> V2 { V2(a.x+b.x, a.y+b.y) }
	public static func - (a: V2, b: V2) -> V2 { V2(a.x-b.x, a.y-b.y) }
	public static func * (a: V2, b: Double) -> V2 { V2(a.x*b, a.y*b) }
	public static func / (a: V2, b: Double) -> V2 { V2(a.x/b, a.y/b) }
	
	public func dot(_ a: V2) -> Double { x*a.x+y*a.y }
	public func det(_ a: V2) -> Double { x*a.y-y*a.x }
    public func innerAngle(_ a: V2) -> Double { acos(dot(a)/len()/a.len()) }
	public func clockwiseAngle(_ a: V2) -> Double { atan2(det(a), dot(a)) }

	public static let zero: V2 = V2(0, 0)
}

public extension CGPoint {
    var v2: V2 { V2(x, y) }
}

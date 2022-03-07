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
	
	public func len() -> Double {
		return sqrt(x*x+y*y)
	}
	
	public static func + (a: V2, b: V2) -> V2 {
		return V2(a.x+b.x, a.y+b.y)
	}
	public static func - (a: V2, b: V2) -> V2 {
		return V2(a.x-b.x, a.y-b.y)
	}
	public static func * (a: V2, b: Double) -> V2 {
		return V2(a.x*b, a.y*b)
	}
	public static func / (a: V2, b: Double) -> V2 {
		return V2(a.x/b, a.y/b)
	}
	
	public static func dot(_ a: V2, _ b: V2) -> Double {
		return a.x*b.x+a.y*b.y
	}
	public static func det(_ a: V2, _ b: V2) -> Double {
		return a.x*b.y-a.y*b.x
	}
	public static func innerAngle(_ a: V2, _ b: V2) -> Double {
		return acos(dot(a,b)/a.len()/b.len())
	}
	public static func clockwiseAngle(_ a: V2, _ b: V2) -> Double {
		return atan2(det(a,b), dot(a,b))
	}

	public static let zero: V2 = V2(0, 0)
}

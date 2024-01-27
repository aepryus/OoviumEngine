//
//  V3.swift
//  OoviumEngine
//
//  Created by Joe Charlier on 1/15/23.
//  Copyright © 2023 Aepryus Software. All rights reserved.
//

import Foundation

public struct V3 {
    public var x: Double
    public var y: Double
    public var z: Double

    public init(_ x: Double, _ y: Double, _ z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }
    
    public func len() -> Double { sqrt(x*x + y*y + z*z) }
    public func lenSq() -> Double { x*x + y*y + z*z }
    public func unit() -> V3 { self/len() }

    public static func + (a: V3, b: V3) -> V3 { V3(a.x+b.x, a.y+b.y, a.z+b.z) }
    public static func - (a: V3, b: V3) -> V3 { V3(a.x-b.x, a.y-b.y, a.z-b.z) }
    public static func * (a: V3, b: Double) -> V3 { V3(a.x*b, a.y*b, a.z*b) }
    public static func / (a: V3, b: Double) -> V3 { V3(a.x/b, a.y/b, a.z/b) }
    
    public func dot(_ a: V3) -> Double { x*a.x + y*a.y + z*a.z }
    public func cross(_ a: V3) -> V3 { V3(y*a.z-z*a.y, z*a.x-x*a.z, x*a.y-y*a.x) }
    public func det(_ a: V3) -> Double { x*a.y-y*a.x }
    public func innerAngle(_ a: V3) -> Double { acos(dot(a)/len()/a.len()) }
    public func clockwiseAngle(_ a: V3) -> Double { atan2(det(a), dot(a)) }

    public static let zero: V3 = V3(0, 0, 0)
}

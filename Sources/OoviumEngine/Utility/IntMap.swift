//
//  IntMap.swift
//  Oovium
//
//  Created by Joe Charlier on 7/16/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import Foundation

class IntMap: CustomStringConvertible {
	var map = [String:Int]()
	
	func set(key: String, to: Int) {
		map[key] = to
	}
	func get(key: String) -> Int {
		if let value = map[key] {
			return value
		} else {
			return 0
		}
	}

	func increment(key: String, by: Int) -> Int {
		if let value = map[key] {
			map[key] = value+by
		} else {
			map[key] = by
		}
		return map[key]!
	}
	func increment(key: String) -> Int {
		return increment(key:key, by:1)
	}
	func decrement(key: String) -> Int {
		return increment(key:key, by:-1)
	}
	func reset(key: String) {
		map.removeValue(forKey: key)
	}
	
// CustomStringConvertible =========================================================================
	var description: String {
		var sb = String()
		for key in map.keys {
			sb.append("\(key):\(map[key]!)\n")
		}
		return sb
	}
}

//
//  Variable.swift
//  Oovium
//
//  Created by Joe Charlier on 5/5/21.
//  Copyright © 2021 Aepryus Software. All rights reserved.
//

import Foundation

class Variable {
	let name: String

	init(name: String) { self.name = name }

	static func == (a: Variable, b: Variable) -> Bool { a.name == b.name }
}

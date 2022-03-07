//
//  Equation.swift
//  Oovium
//
//  Created by Joe Charlier on 5/5/21.
//  Copyright © 2021 Aepryus Software. All rights reserved.
//

import Foundation

class Equation {
	let left: Expression
	let right: Expression

	init(left: Expression, right: Expression) {
		self.left = left
		self.right = right
	}

	func solve(for variable: Variable) -> Expression? {
		guard left.depends(on: variable) || right.depends(on: variable) else { return nil }

		print("\n[ Solving ] ========================")
		print("\t\(left) = \(right)")

		var left: Expression = self.left.reduce()
		var right: Expression = self.right.reduce()

		print("\t\(left) = \(right)")

		while right.depends(on: variable) {
			guard let actor: Actor = right.attemptToRemove(variable: variable) else { break }
			left = actor.act(on: left)
			right = actor.act(on: right)
			print("\t\(left) = \(right)")
		}

		guard !right.depends(on: variable) else { return nil }

		while !left.isolated(to: variable) {
			guard let actor: Actor = left.attemptToIsolate(variable: variable) else { break }
			left = actor.act(on: left)
			right = actor.act(on: right)
			print("\t\(left) = \(right)")
		}
		print("====================================\n")

		guard left.isolated(to: variable) else { return nil }

		return right
	}
}

//
//  Tower.swift
//  Oovium
//
//  Created by Joe Charlier on 10/1/16.
//  Copyright © 2016 Aepryus Software. All rights reserved.
//

import Aegean
import Acheron
import Foundation

protocol TowerDelegate: AnyObject {
	func buildUpstream(tower: Tower)
	func renderDisplay(tower: Tower) -> String
	func buildWorker(tower: Tower)
	func workerCompleted(tower: Tower, askedBy: Tower) -> Bool
	func workerBlocked(tower: Tower) -> Bool
	func resetWorker(tower: Tower)
	func executeWorker(tower: Tower)
}
extension TowerDelegate {
	func buildUpstream(tower: Tower) {}
	func renderDisplay(tower: Tower) -> String { "---" }
	func buildWorker(tower: Tower) {}
	func workerCompleted(tower: Tower, askedBy: Tower) -> Bool { true }
	func workerBlocked(tower: Tower) -> Bool { false }
	func resetWorker(tower: Tower) {}
	func executeWorker(tower: Tower) {}
}

public protocol TowerListener: AnyObject {
	func onTriggered()
}

class Funnel {
	let options: [Tower]
	let spout: Tower
	
	init(options: [Tower], spout: Tower) {
		self.options = options
		self.spout = spout
	}
}

public final class Tower: Hashable, CustomStringConvertible {
	unowned let aether: Aether
	public let variableToken: VariableToken
	public let functionToken: FunctionToken?
	unowned let delegate: TowerDelegate

	var upstream: WeakSet<Tower> = WeakSet<Tower>()
	var downstream: WeakSet<Tower> = WeakSet<Tower>()

	public weak var listener: TowerListener? = nil

	var tailForWeb: AnyObject? = nil
	weak var _web: AnyObject? = nil
	public var web: AnyObject? {
		set { _web = newValue }
		get {
			if let web = _web { return web }
			for tower in upstream {
				guard tower.tailForWeb == nil else { return nil }
				if let web = tower.web { return web }
			}
			return nil
		}
	}

	public weak var gateTo: Tower?
	public weak var thenTo: Tower?
	public weak var elseTo: Tower?
	public weak var gate: Tower?
	var funnel: Funnel? = nil

	var task: UnsafeMutablePointer<Task>? = nil
	
	var name: String { variableToken.tag }

	init(aether: Aether, token: VariableToken, functionToken: FunctionToken? = nil, delegate: TowerDelegate) {
		self.aether = aether
		self.variableToken = token
		self.functionToken = functionToken
		self.delegate = delegate
	}
	deinit {
		AETaskRelease(task)
	}

	public var index: mnimi { AEMemoryIndexForName(aether.memory, variableToken.tag.toInt8()) }
	public var value: Double { AEMemoryValue(aether.memory, index) }
	public var obje: Obje { Obje(memory: aether.memory, index: index) }
	
	func workerCompleted(askedBy: Tower) -> Bool { delegate.workerCompleted(tower: self, askedBy: askedBy) }
	
// Stream ==========================================================================================
	public func attach(_ tower: Tower) {
		downstream.insert(tower)
		tower.upstream.insert(self)
	}
	public func detach(_ tower: Tower) {
		downstream.remove(tower)
		tower.upstream.remove(self)
	}
	public func abstract() {
		abstractUp()
		downstream.forEach {$0.upstream.remove(self)}
		downstream.removeAll()
	}
	public func abstractUp() {
		upstream.forEach {$0.downstream.remove(self)}
		upstream.removeAll()
	}
	
	private func loadDownstream(into towers: inout Set<Tower>) {
		guard !towers.contains(self) else { return }
		towers.insert(self)
		downstream.forEach { $0.loadDownstream(into: &towers) }
	}
	public func allDownstream() -> Set<Tower> {
		var towers: Set<Tower> = Set()
		loadDownstream(into: &towers)
		return towers
	}
	public func downstream(contains: Tower) -> Bool {
		if self === contains {return true}
		guard tailForWeb == nil else {return false}
		for tower in downstream {
			if tower.downstream(contains: contains) {
				return true
			}
		}
		return false
	}
	
	public func towersDestinedFor() -> Set<Tower> {
		var result = Set<Tower>()
		guard web != nil else {return result}
		result.insert(self)
		upstream.forEach {result.formUnion($0.towersDestinedFor())}
		return result
	}
	private func isStronglyLinked(to: Tower, override: Tower?) -> Bool {
		if self == to || self == override {return true}
		if self.funnel != nil {return false}
		for tower in downstream {
			if tower.isStronglyLinked(to: to, override: override) {
				return true
			} else if let funnel = tower.funnel, funnel.spout.isStronglyLinked(to: to, override: override) {
				var inAll: Bool = true
				funnel.options.forEach {if !downstream(contains: $0) {inAll = false}}
				if inAll {return true}
			}
		}
		return false
	}
	public func stronglyLinked(override: Tower?) -> Set<Tower> {
		return towersDestinedFor().filter {$0.isStronglyLinked(to: self, override: override)}
	}
	public func stronglyLinked() -> Set<Tower> {
		return stronglyLinked(override: nil)
	}

// Program =========================================================================================
	private func isCalced(_ memory: UnsafeMutablePointer<Memory>) -> Bool {
		return AEMemoryLoaded(memory, index) != 0
	}
	func attemptToFire(_ memory: UnsafeMutablePointer<Memory>) -> Bool {
		if isCalced(memory) { return false }
		
		if let gate = gate {
			if !gate.isCalced(memory) { return false }
		}
		
		for tower in upstream {
			if tower.task == nil { continue }
			if !tower.isCalced(memory) { return false }
		}
		
		memory.pointee.slots[Int(index)].loaded = 1
		return true
	}
	
// Calculate =======================================================================================
	public func buildStream() {
		delegate.buildUpstream(tower: self)
	}
	public func buildTask() {
		AETaskRelease(task)
		delegate.buildWorker(tower: self)
	}
	var calced: Bool {
		return variableToken.type != .variable || AEMemoryLoaded(aether.memory, index) != 0
	}
	func attemptToCalculate() -> Bool {
		guard !workerCompleted(askedBy: self),
			  !upstream.contains(where: { !$0.workerCompleted(askedBy: self) })
			else { return false }

		if variableToken.status == .ok || variableToken.status == .blocked {
			variableToken.status = delegate.workerBlocked(tower: self) ? .blocked : .ok
			functionToken?.status = variableToken.status
		}

		// This was necessitated because data types can change. ====
		// It might be better to detect a change and trigger then. =
		buildTask()
		// =========================================================

		if (web != nil && variableToken.def !== LambdaDef.def) || variableToken.status != .ok {
			variableToken.label = delegate.renderDisplay(tower: self)
			AEMemorySetValue(aether.memory, index, 0)
			return true
		}
		
		delegate.executeWorker(tower: self)

		return true
	}
	public func trigger() {
		aether.evaluate(from: self)
	}
	
// Hashable ========================================================================================
	public static func == (left: Tower, right: Tower) -> Bool {
		return left === right
	}
	public func hash(into hasher: inout Hasher) {
		hasher.combine(name)
	}
	
// CustomStringConvertible =========================================================================
	public var description: String {
		var sb: String = ""

		sb.append("Tower [\(name)\n")
		sb.append("\tupstream:\n")
		for tower in upstream
			{sb.append("\t\t\(tower.name)\n")}
		sb.append("\tdownstream:\n")
		for tower in downstream
			{sb.append("\t\t\(tower.name)\n")}

		return sb;
	}
	
// Static ==========================================================================================
	public static func printTowers(_ towers: WeakSet<Tower>) {
		print("[ Towers =================================== ]\n")
		for tower in towers { print("\(tower)") }
		print("[ ========================================== ]\n\n")
	}
    public static func printTowers(_ towers: Set<Tower>) {
        print("[ Towers =================================== ]\n")
        for tower in towers { print("\(tower)") }
        print("[ ========================================== ]\n\n")
    }
	static func printTowers(_ towers: [Tower]) {
		print("[ Towers =================================== ]\n")
		towers.forEach { print("\($0)") }
		print("[ ========================================== ]\n\n")
	}
}

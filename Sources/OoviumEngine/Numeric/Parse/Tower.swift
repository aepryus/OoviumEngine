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

public protocol TowerListener: AnyObject {
	func onTriggered()
}
public class Fog {
    let key: TokenKey
    init(_ key: TokenKey) { self.key = key }
}

class Funnel {
	let options: [Tower]
	let spout: Tower
	
	init(options: [Tower], spout: Tower) {
		self.options = options
		self.spout = spout
	}
}

public class Tower: Hashable, CustomStringConvertible {
    private unowned let aetherExe: AetherExe
    let core: Core?

    private let _variableToken: VariableToken
    public lazy var variableToken: VariableToken = { _variableToken.tower = self; return _variableToken }()

    private let _mechlikeToken: MechlikeToken? = nil
    public lazy var mechlikeToken: MechlikeToken? = { _mechlikeToken?.tower = self; return _mechlikeToken }()

	var upstream: WeakSet<Tower> = WeakSet<Tower>()
	var downstream: WeakSet<Tower> = WeakSet<Tower>()

	public weak var listener: TowerListener? = nil

    public var fog: TokenKey? { core?.fog }
    public var isFogFirewall: Bool { core?.fog != nil }

	public weak var gateTo: Tower?
	public weak var thenTo: Tower?
	public weak var elseTo: Tower?
	public weak var gate: Tower?
	var funnel: Funnel? = nil

	var task: UnsafeMutablePointer<Task>? = nil
	
	var name: String { variableToken.tag }
    var memory: UnsafeMutablePointer<Memory> { aetherExe.memory }
    
    init(aetherExe: AetherExe, token: VariableToken, core: Core) {
		self.aetherExe = aetherExe
        self._variableToken = token
		self.core = core
	}
	deinit { AETaskRelease(task) }

	public var index: mnimi {
        AEMemoryIndexForName(aetherExe.memory, variableToken.tag.toInt8())
    }
    public var value: Double { AEMemoryValue(aetherExe.memory, index) }
    public var obje: Obje { Obje(memory: aetherExe.memory, index: index) }
	
	func taskCompleted(askedBy: Tower) -> Bool { core?.taskCompleted(tower: self, askedBy: askedBy) ?? true }

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
		if self === contains { return true }
        guard !isFogFirewall else { return false }
		for tower in downstream {
			if tower.downstream(contains: contains) {
				return true
			}
		}
		return false
	}
	
	public func towersDestinedFor() -> Set<Tower> {
		var result = Set<Tower>()
		guard fog != nil else {return result}
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
	public func stronglyLinked(override: Tower? = nil) -> Set<Tower> {
		towersDestinedFor().filter {$0.isStronglyLinked(to: self, override: override)}
	}

// Program =========================================================================================
	private func isCalced(_ memory: UnsafeMutablePointer<Memory>) -> Bool { AEMemoryLoaded(memory, index) != 0 }
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
	public func buildStream() { core?.buildUpstream(tower: self) }
	public func buildTask() {
        guard let core, variableToken.status != .deleted else { return }
		AETaskRelease(task)
        task = core.renderTask(tower: self)
	}
    var calced: Bool { variableToken.code != .va || AEMemoryLoaded(aetherExe.memory, index) != 0 }
	func attemptToCalculate() -> Bool {
        guard let core else { return false }
		guard !taskCompleted(askedBy: self),
			  !upstream.contains(where: { !$0.taskCompleted(askedBy: self) })
			else { return false }

		if variableToken.status == .ok || variableToken.status == .blocked {
			variableToken.status = core.taskBlocked(tower: self) ? .blocked : .ok
            mechlikeToken?.status = variableToken.status
		}

		// This was necessitated because data types can change. ====
		// It might be better to detect a change and trigger then. =
		buildTask()
		// =========================================================

		if (fog != nil && variableToken.def !== LambdaDef.def) || variableToken.status != .ok {
			variableToken.details = core.renderDisplay(tower: self)
            AEMemorySetValue(aetherExe.memory, index, 0)
			return true
        } else { variableToken.details = nil }
		
        core.executeTask(tower: self)

		return true
	}
    public func trigger() { Tower.evaluate(towers: allDownstream()) }
	
// Hashable ========================================================================================
	public static func == (left: Tower, right: Tower) -> Bool { left === right }
	public func hash(into hasher: inout Hasher) { hasher.combine(name) }
	
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
    public static func allDownstream(towers: Set<Tower>) -> Set<Tower> {
        var result: Set<Tower> = Set<Tower>()
        towers.forEach { result.formUnion($0.allDownstream()) }
        return result
    }
    public static func evaluate(towers: Set<Tower>) {
        towers.forEach { $0.core?.resetTask(tower: $0) }
        var progress: Bool
        repeat {
            progress = false
            towers.forEach { if $0.attemptToCalculate() { progress = true } }
        } while progress
    }
    public static func notifyListeners(towers: [Tower]) {
        towers.compactMap({ listeners[$0.variableToken.key] }).forEach { $0.onTriggered() }
    }
    
    private static var listeners: [TokenKey:TowerListener] = [:]
    public static func startListening(to key: TokenKey, listener: TowerListener) { listeners[key] = listener }
    public static func stopListeneing(to key: TokenKey) { listeners[key] = nil }

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

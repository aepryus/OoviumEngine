//
//  Migrate.swift
//  Oovium
//
//  Created by Joe Charlier on 12/31/16.
//  Copyright © 2016 Aepryus Software. All rights reserved.
//

import Acheron
import Foundation

enum AetherLoadingError: Error {
    case fromNewerVersion(currentVersion: String, fileVersion: String)
}

fileprivate struct Subs {
    let from: String
    let to: String
}

public extension Dictionary where Key == String {
    func modify(condition: (Self)->(Bool), action: (Self, Int)->(Self), no: Int = 0) -> Self {
        var result: Self = [:]
        if condition(self) { result = action(self, no) }
        else {
            keys.forEach { (key: String) in
                if let subAtts = self[key] as? [String:Value] { result[key] = subAtts.modify(condition: condition, action: action) as? Value }
                else if let subArray = self[key] as? [[String:Value]] {
                    var subResult: [[String:Value]] = []
                    var no: Int = 1
                    subArray.forEach {
                        subResult.append($0.modify(condition: condition, action: action, no: no))
                        no += 1
                    }
                    result[key] = subResult as? Value
                } else {
                    result[key] = self[key]
                }
            }
        }
        return result
    }
}

public class Migrate {
	public static func migrateChainFromXML(_ from: Any?, colToGrid: [Int:Int], cellToGrid: [Int:Int]) -> String? {
		guard let keys = (from as? String)?.split(separator: ";") else {return nil}
		var sb: String = ""
		for _key in keys {
			let key: String = String(_key)
			let colon: Int = key.loc(of: ":")!
			let type: Int = Int(key[..<colon])!
			let tag: String = String(key[(colon+1)...])
			
			switch type {
				case 0, 1, 4:	sb += "\(type):"
				case 2:			sb += "3:"
				case 3:			sb += "7:"
				case 5:			sb += "6:"
				case 6:			sb += "2:"
				case 8:			sb += "5:"
				default:		sb += ""
			}
            if type == 4 && tag.loc(of: ".") == nil && tag != "k" && tag != "π" && tag != "e" {
                let i: Int = tag.count-5
                let prefix: String = tag[..<i]
                let no: Int = Int(tag[i...])!
                switch prefix {
                    case "I":	sb += "Ob_\(no)"
                    case "CB":	sb += "Cr_\(no)"
                    case "IF":	sb += "GtR_\(no)"
                    case "L":	sb += "Gr\(cellToGrid[no]!).Ce\(no)"
                    case "C":	sb += "Gr\(colToGrid[no]!).Co\(no)"
                    case "F":	sb += "Gr\(colToGrid[no]!).Ft\(no)"
                    default:	fatalError()
                }
            } else if type == 4 && ["π", "e", "i"].contains(tag) {
                sb.removeLast(2)
                sb += "6:\(tag)"
			} else if type == 1 && tag == "&" {
				sb += "&&"
			} else if type == 1 && tag == "|" {
				sb += "||"
			} else {
				sb += tag
			}
			sb += ";"
		}
		if sb.count > 0 { sb.removeLast() }
		return sb
	}
	public static func migrateXMLtoJSON(_ xml: [String:Any]) -> [String:Any] {
		var cellToGrid: [Int:Int] = [:]
		var colToGrid: [Int:Int] = [:]
	
		if let xmlArray: [[String:Any]] = xml["children"] as? [[String:Any]] {
			for xmlAtts: [String:Any] in xmlArray {
				if xmlAtts["type"] as! String == "grid" {
					let gridNo: Int = Int(xmlAtts["gridID"] as! String)!
					if let xmlArray2 = xmlAtts["children"] as? [[String:Any]] {
						for xmlAtts2: [String:Any] in xmlArray2 {
							if xmlAtts2["type"] as! String == "col" {
								let colNo = Int(xmlAtts2["colID"] as! String)!
								colToGrid[colNo] = gridNo
							} else if xmlAtts2["type"] as! String == "cell" {
								let cellNo = Int(xmlAtts2["cellID"] as! String)!
								cellToGrid[cellNo] = gridNo
							}
						}
					}
				}
			}
		}
	
		var json: [String:Any] = [:]
			
		json["iden"] = UUID().uuidString
		json["no"] = Int(xml["aetherID"] as! String)
		json["type"] = "aether"
		json["name"] = xml["name"]
		json["readOnly"] = xml["readOnly"]
		json["xOffset"] = xml["offsetX"]
		json["yOffset"] = xml["offsetY"]
		
		var aexelArray: [[String:Any]] = []
		
		if let xmlArray: [[String:Any]] = xml["children"] as? [[String:Any]] {
			for xmlAtts: [String:Any] in xmlArray {
				if xmlAtts["type"] as! String == "instance" {
					var jsonAtts: [String:Any] = [:]
					jsonAtts["iden"] = UUID().uuidString
					jsonAtts["no"] = Int(xmlAtts["instanceID"] as! String)
					jsonAtts["name"] = "Ob_\(jsonAtts["no"] as! Int)"
					jsonAtts["type"] = "object"
					jsonAtts["label"] = xmlAtts["name"]
					jsonAtts["x"] = xmlAtts["x"]
					jsonAtts["y"] = xmlAtts["y"]
					jsonAtts["chain"] = migrateChainFromXML(xmlAtts["tokens"], colToGrid: colToGrid, cellToGrid: cellToGrid)
					aexelArray.append(jsonAtts)
				}
				
				if xmlAtts["type"] as! String == "if" {
					var jsonAtts: [String:Any] = [:]
					jsonAtts["iden"] = UUID().uuidString
					jsonAtts["no"] = Int(xmlAtts["ifID"] as! String)
					jsonAtts["type"] = "gate"
					jsonAtts["name"] = xmlAtts["name"]
					jsonAtts["x"] = xmlAtts["x"]
					jsonAtts["y"] = xmlAtts["y"]
					jsonAtts["ifChain"] = migrateChainFromXML(xmlAtts["ifString"], colToGrid: colToGrid, cellToGrid: cellToGrid)
					jsonAtts["thenChain"] = migrateChainFromXML(xmlAtts["thenString"], colToGrid: colToGrid, cellToGrid: cellToGrid)
					jsonAtts["elseChain"] = migrateChainFromXML(xmlAtts["elseString"], colToGrid: colToGrid, cellToGrid: cellToGrid)
					aexelArray.append(jsonAtts)
				}
				
				if xmlAtts["type"] as! String == "mech" {
					var jsonAtts: [String:Any] = [:]
					jsonAtts["iden"] = UUID().uuidString
					jsonAtts["no"] = Int(xmlAtts["mechID"] as! String)
					jsonAtts["type"] = "mech"
					jsonAtts["name"] = xmlAtts["name"]
					jsonAtts["x"] = xmlAtts["x"]
					jsonAtts["y"] = xmlAtts["y"]
					jsonAtts["resultChain"] = migrateChainFromXML(xmlAtts["tokens"], colToGrid: colToGrid, cellToGrid: cellToGrid)
					if let xmlArray2 = xmlAtts["children"] as? [[String:Any]] {
						var inputArray = [[String:Any]]()
						for xmlAtts2: [String:Any] in xmlArray2 {
							if xmlAtts2["type"] as! String == "input" {
								var jsonAtts2: [String:Any] = [:]
								jsonAtts2["iden"] = UUID().uuidString
								jsonAtts2["no"] = Int(xmlAtts2["inputID"] as! String)
								jsonAtts2["type"] = "input"
								jsonAtts2["name"] = xmlAtts2["name"]
								jsonAtts2["def"] = "real"
								inputArray.append(jsonAtts2)
							}
						}
						jsonAtts["inputs"] = inputArray
					}
					aexelArray.append(jsonAtts)
				}
				
				if xmlAtts["type"] as! String == "tail" {
					var jsonAtts: [String:Any] = [:]
					jsonAtts["iden"] = UUID().uuidString
					jsonAtts["no"] = Int(xmlAtts["tailID"] as! String)
					jsonAtts["type"] = "tail"
					jsonAtts["name"] = xmlAtts["name"]
					jsonAtts["x"] = xmlAtts["x"]
					jsonAtts["y"] = xmlAtts["y"]
					jsonAtts["whileChain"] = migrateChainFromXML(xmlAtts["condition"], colToGrid: colToGrid, cellToGrid: cellToGrid)
					jsonAtts["resultChain"] = migrateChainFromXML(xmlAtts["result"], colToGrid: colToGrid, cellToGrid: cellToGrid)
					if let xmlArray2 = xmlAtts["children"] as? [[String:Any]] {
						var vertebraArray = [[String:Any]]()
						for xmlAtts2: [String:Any] in xmlArray2 {
							if xmlAtts2["type"] as! String == "vertebra" {
								var jsonAtts2: [String:Any] = [:]
								jsonAtts2["iden"] = UUID().uuidString
								jsonAtts2["no"] = Int(xmlAtts2["vertebraID"] as! String)
								jsonAtts2["type"] = "vertebra"
								jsonAtts2["name"] = xmlAtts2["name"]
								jsonAtts2["def"] = "real"
								jsonAtts2["chain"] = migrateChainFromXML(xmlAtts2["tokens"], colToGrid: colToGrid, cellToGrid: cellToGrid)
								vertebraArray.append(jsonAtts2)
							}
						}
						jsonAtts["vertebras"] = vertebraArray
					}
					aexelArray.append(jsonAtts)
				}
				
				if xmlAtts["type"] as! String == "grid" {
					var jsonAtts: [String:Any] = [:]
					jsonAtts["iden"] = UUID().uuidString
					jsonAtts["no"] = Int(xmlAtts["gridID"] as! String)
					jsonAtts["type"] = "grid"
					jsonAtts["name"] = xmlAtts["name"]
					jsonAtts["x"] = xmlAtts["x"]
					jsonAtts["y"] = xmlAtts["y"]
					jsonAtts["rows"] = xmlAtts["rows"]
					if let xmlArray2 = xmlAtts["children"] as? [[String:Any]] {
						var columnArray = [[String:Any]]()
						var cellArray = [[String:Any]]()
						var colIDtoColNo: [Int:Int] = [:]
						var colNo: Int = 0
						for xmlAtts2: [String:Any] in xmlArray2 {
							if xmlAtts2["type"] as! String == "col" {
								var jsonAtts2: [String:Any] = [:]
								jsonAtts2["iden"] = UUID().uuidString
								jsonAtts2["no"] = Int(xmlAtts2["colID"] as! String)
								jsonAtts2["type"] = "column"
								jsonAtts2["name"] = xmlAtts2["name"]
								jsonAtts2["def"] = "real"
								jsonAtts2["chain"] = migrateChainFromXML(xmlAtts2["tokens"], colToGrid: colToGrid, cellToGrid: cellToGrid)
								jsonAtts2["aggregate"] = xmlAtts2["aggregate"]
								let oldJustify: Int = Int(xmlAtts2["justify"] as! String)!
								jsonAtts2["justify"] = oldJustify == 0 ? 1 : (oldJustify == 1 ? 2 : 0)
								jsonAtts2["format"] = xmlAtts2["format"]
								columnArray.append(jsonAtts2)
								colIDtoColNo[jsonAtts2["no"] as! Int] = colNo
								colNo += 1
                            } else if xmlAtts2["type"] as! String == "cell", let colNo: Int = colIDtoColNo[Int(xmlAtts2["colID"] as! String)!] {
								var jsonAtts2: [String:Any] = [:]
								jsonAtts2["iden"] = UUID().uuidString
								jsonAtts2["no"] = Int(xmlAtts2["cellID"] as! String)
								jsonAtts2["type"] = "cell"                                
								jsonAtts2["colNo"] = colNo
								jsonAtts2["rowNo"] = Int(xmlAtts2["rowNo"] as! String)
								jsonAtts2["chain"] = migrateChainFromXML(xmlAtts2["tokens"], colToGrid: colToGrid, cellToGrid: cellToGrid)
								cellArray.append(jsonAtts2)
							}
						}
						jsonAtts["columns"] = columnArray
						jsonAtts["cells"] = cellArray.sorted(by: { (left: [String : Any], right: [String : Any]) -> Bool in
							if (left["rowNo"] as! Int) == (right["rowNo"] as! Int) { return (left["colNo"] as! Int) < (right["colNo"] as! Int) }
							return (left["rowNo"] as! Int) < (right["rowNo"] as! Int)
						})
					}
					aexelArray.append(jsonAtts)
				}
				
				if xmlAtts["type"] as! String == "Cron" {
					var jsonAtts: [String:Any] = [:]
					jsonAtts["iden"] = UUID().uuidString
					jsonAtts["no"] = Int(xmlAtts["cronID"] as! String)
					jsonAtts["type"] = "cron"
					jsonAtts["name"] = xmlAtts["name"]
					jsonAtts["x"] = xmlAtts["x"]
					jsonAtts["y"] = xmlAtts["y"]
					jsonAtts["startChain"] = migrateChainFromXML(xmlAtts["start"], colToGrid: colToGrid, cellToGrid: cellToGrid)
					jsonAtts["stopChain"] = migrateChainFromXML(xmlAtts["stop"], colToGrid: colToGrid, cellToGrid: cellToGrid)
					jsonAtts["stepsChain"] = migrateChainFromXML(xmlAtts["steps"], colToGrid: colToGrid, cellToGrid: cellToGrid)
					jsonAtts["rateChain"] = migrateChainFromXML(xmlAtts["rate"], colToGrid: colToGrid, cellToGrid: cellToGrid)
					jsonAtts["deltaChain"] = migrateChainFromXML(xmlAtts["delta"], colToGrid: colToGrid, cellToGrid: cellToGrid)
					jsonAtts["whileChain"] = migrateChainFromXML(xmlAtts["whyle"], colToGrid: colToGrid, cellToGrid: cellToGrid)
					jsonAtts["endMode"] = xmlAtts["endMode"]
					jsonAtts["exposed"] = xmlAtts["exposed"]
					aexelArray.append(jsonAtts)
				}
				
				if xmlAtts["type"] as! String == "oval" {
					var jsonAtts: [String:Any] = [:]
					jsonAtts["iden"] = UUID().uuidString
					jsonAtts["no"] = Int(xmlAtts["ovalID"] as! String)
					jsonAtts["type"] = "text"
					jsonAtts["name"] = xmlAtts["text"]
					jsonAtts["x"] = xmlAtts["x"]
					jsonAtts["y"] = xmlAtts["y"]

                    switch xmlAtts["shape"] as! String {
                        case "1": jsonAtts["shape"] = "2"
                        case "2": jsonAtts["shape"] = "1"
                        default: jsonAtts["shape"] = xmlAtts["shape"]
                    }
                    
					jsonAtts["color"] = xmlAtts["color"]
					if let xmlArray2 = xmlAtts["children"] as? [[String:Any]] {
						var edgeArray = [[String:Any]]()
						for xmlAtts2: [String:Any] in xmlArray2 {
							if xmlAtts2["type"] as! String == "link" {
								var jsonAtts2: [String:Any] = [:]
								jsonAtts2["iden"] = UUID().uuidString
								jsonAtts2["no"] = Int(xmlAtts2["linkID"] as! String)
								jsonAtts2["type"] = "edge"
								jsonAtts2["textNo"] = xmlAtts2["linkedID"]
								edgeArray.append(jsonAtts2)
							}
						}
						jsonAtts["edges"] = edgeArray
					}
					aexelArray.append(jsonAtts)
				}
				
				if xmlAtts["type"] as! String == "cast" {
					var jsonAtts: [String:Any] = [:]
					jsonAtts["iden"] = UUID().uuidString
					jsonAtts["no"] = Int(xmlAtts["castID"] as! String)
					jsonAtts["type"] = "type"
					jsonAtts["name"] = xmlAtts["name"]
					jsonAtts["x"] = xmlAtts["x"]
					jsonAtts["y"] = xmlAtts["y"]
					jsonAtts["color"] = xmlAtts["color"]
					if let xmlArray2 = xmlAtts["children"] as? [[String:Any]] {
						var fieldArray = [[String:Any]]()
						for xmlAtts2: [String:Any] in xmlArray2 {
							if xmlAtts2["type"] as! String == "field" {
								var jsonAtts2: [String:Any] = [:]
								jsonAtts2["iden"] = UUID().uuidString
								jsonAtts2["no"] = Int(xmlAtts2["fieldID"] as! String)
								jsonAtts2["type"] = "field"
								jsonAtts2["name"] = xmlAtts2["name"]
								jsonAtts2["typeName"] = xmlAtts2["typeName"]
								jsonAtts2["orderNo"] = xmlAtts2["fieldNo"]
								fieldArray.append(jsonAtts2)
							}
						}
						jsonAtts["fields"] = fieldArray
					}
					aexelArray.append(jsonAtts)
				}
				
				if xmlAtts["type"] as! String == "include" {
					var jsonAtts: [String:Any] = [:]
					jsonAtts["iden"] = UUID().uuidString
					jsonAtts["no"] = Int(xmlAtts["includeID"] as! String)
					jsonAtts["type"] = "also"
					jsonAtts["aetherName"] = xmlAtts["includedName"]
					jsonAtts["x"] = 500
					jsonAtts["y"] = 500
					aexelArray.append(jsonAtts)
				}
			}
		}
		
		if aexelArray.count > 0 { json["aexels"] = aexelArray }

		return json
	}
	public static func migrateChainTo21(_ tokensString: String) -> String {
		let keys: [String] = tokensString.components(separatedBy: ";")

		var sb: String = ""
		keys.forEach {
			if $0 == "1:neg" { sb.append("8:-;") }
			else if $0 == "1:!" { sb.append("8:!;") }
			else { sb.append("\($0);") }
		}

		if sb.count > 0 { sb.removeLast() }
		return sb
	}
    fileprivate static func migrateChainTo30(_ tokensString: String, subs: [Subs]) -> String {
        guard tokensString != "" else {
            return ""
        }
        let keys: [String] = tokensString.components(separatedBy: ";")

        var sb: String = ""
        keys.forEach {
            let old: String = $0[0...0]
            switch old {
                case "0": sb.append("dg")
                case "1": sb.append("op")
                case "2": sb.append("sp")
                case "3":
                    if Token.token(key: TokenKey("fn:\($0[2...])")) != nil { sb.append("fn") }
                    else { sb.append("ml") }
                case "4": sb.append("va")
                case "5": sb.append("pr")
                case "6": sb.append("cn")
                case "7": sb.append("ch")
                case "8": sb.append("un")
                default:  sb.append("")
            }
            sb.append(":")
            
            var tag: String = $0[2...]
            tag = tag.replacingOccurrences(of: "Ob_", with: "Ob")
            tag = tag.replacingOccurrences(of: "GtR_", with: "Gt")
            tag = tag.replacingOccurrences(of: "Cr_", with: "Cr")
            
            subs.forEach { if tag == $0.from { tag = $0.to } }

            sb.append(tag)
            sb.append(";")
        }

        if sb.count > 0 { sb.removeLast() }
        
        return sb
    }
    fileprivate static func migrateChainTo31(_ tokensString: String, subs: [Subs]) -> String {
        
        let divider: Int = tokensString.loc(of: "::")!
        let key: String = tokensString[0...(divider-1)]
        let keys: [String] = tokensString[(divider+2)...].components(separatedBy: ";")
        
        guard tokensString.count > divider + 2 else { return tokensString }

        var sb: String = "\(key)::"
        keys.forEach {
            sb.append($0[0...2])
            
            var tag: String = $0[3...]
            
            subs.forEach { if tag == $0.from { tag = $0.to } }

            sb.append(tag)
            sb.append(";")
        }

        if sb.count > 0 { sb.removeLast() }
        
        return sb
    }
	public static func migrateAether(json: String) throws -> String {
		var attributes: [String:Any] = json.toAttributes()
		let fileVersion: String = attributes["version"] as? String ?? "2.0.2"
        
        let result: ComparisonResult =  fileVersion.compare(Aether.engineVersion, options: .numeric)
        
        guard result != .orderedDescending else { throw AetherLoadingError.fromNewerVersion(currentVersion: Aether.engineVersion, fileVersion: fileVersion) }
        guard result != .orderedSame else { return json }

        let chainNames: [String] = ["chain", "ifChain", "thenChain", "elseChain", "resultChain", "whileChain", "startChain", "stopChain", "stepChain", "rateChain", "deltaChain", "statesChain", "amorousChain"]

		print("migrate file from [\(fileVersion)] to [\(Aether.engineVersion)]")
        
        var migrate: Bool = false
        
        if fileVersion == "2.0.2" { migrate = true }
        if migrate {
            attributes = attributes.modify(query: chainNames, convert: { (value: Any) in
                Migrate.migrateChainTo21(value as! String)
            })
        }
        
        if fileVersion == "2.1" { migrate = true }
        if migrate {
            attributes["version"] = "3.0"
            attributes = attributes.modify(condition: { (attributes: [String:Any]) in
                ["input", "vertebra"].contains(attributes["type"] as! String)
            }, action: { (attributes: [String:Any], no: Int) in
                var result: [String:Any] = attributes
                result["no"] = no
                return result
            })
            
            var subs: [Subs] = []
            
            if let aexels: [[String:Any]] = attributes["aexels"] as? [[String:Any]] {
                let mechs: [[String:Any]] = aexels.filter { $0["type"] as! String == "mech" }
                mechs.forEach { (mech: [String:Any]) in
                    subs.append(Subs(from: "\(mech["name"]!)", to: "Me\(mech["no"]!)"))
                    let inputs: [[String:Any]] = mech["inputs"] as! [[String:Any]]
                    var no: Int = 1
                    inputs.forEach { (input: [String:Any]) in
                        subs.append(Subs(from: "\(mech["name"]!).\(input["name"]!)", to: "Me\(mech["no"]!).i\(no)"))
                        no += 1
                    }
                }
                
                let tails: [[String:Any]] = aexels.filter { $0["type"] as! String == "tail" }
                tails.forEach { (tail: [String:Any]) in
                    subs.append(Subs(from: tail["name"] as! String, to: "Ta\(tail["no"]!)"))
                    let vertebras: [[String:Any]] = tail["vertebras"] as! [[String:Any]]
                    var no: Int = 1
                    vertebras.forEach { (vertebra: [String:Any]) in
                        subs.append(Subs(from: "\(tail["name"]!).\(vertebra["name"]!)", to: "Ta\(tail["no"]!).i\(no)"))
                        no += 1
                    }
                }

                let autos: [[String:Any]] = aexels.filter { $0["type"] as! String == "auto" }
                autos.forEach { (auto: [String:Any]) in
                    subs.append(Subs(from: "Auto\(auto["no"]!)", to: "Au\(auto["no"]!)"))
                    subs.append(Subs(from: "Auto\(auto["no"]!).A", to: "Au\(auto["no"]!).A"))
                    subs.append(Subs(from: "Auto\(auto["no"]!).B", to: "Au\(auto["no"]!).B"))
                    subs.append(Subs(from: "Auto\(auto["no"]!).C", to: "Au\(auto["no"]!).C"))
                    subs.append(Subs(from: "Auto\(auto["no"]!).D", to: "Au\(auto["no"]!).D"))
                    subs.append(Subs(from: "Auto\(auto["no"]!).E", to: "Au\(auto["no"]!).E"))
                    subs.append(Subs(from: "Auto\(auto["no"]!).F", to: "Au\(auto["no"]!).F"))
                    subs.append(Subs(from: "Auto\(auto["no"]!).G", to: "Au\(auto["no"]!).G"))
                    subs.append(Subs(from: "Auto\(auto["no"]!).H", to: "Au\(auto["no"]!).H"))
                    subs.append(Subs(from: "Auto\(auto["no"]!).Self", to: "Au\(auto["no"]!).Self"))
                }
            }
            
            attributes = attributes.modify(query: chainNames, convert: { (value: Any) in
                Migrate.migrateChainTo30(value as! String, subs: subs)
            })
        }
        
        if fileVersion == "3.0" { migrate = true }
        if migrate {
            attributes["version"] = "3.1"
            var subs: [Subs] = []

            if var aexelArray: [[String:Any]] = attributes["aexels"] as? [[String:Any]] {
                for (index, var aexelAtts): (Int, [String:Any]) in aexelArray.enumerated() {
                    guard let type: String = aexelAtts["type"] as? String,
                          let no: Int = aexelAtts["no"] as? Int
                    else { continue }
                    
                    switch type {
                        case "object":
                            if let tokens: String = aexelAtts["chain"] as? String { aexelAtts["chain"] = "Ob\(no)::\(tokens)" }
                        case "gate":
                            if let tokens: String = aexelAtts["ifChain"] as? String { aexelAtts["ifChain"] = "Gt\(no).if::\(tokens)" }
                            if let tokens: String = aexelAtts["thenChain"] as? String { aexelAtts["thenChain"] = "Gt\(no).then::\(tokens)" }
                            if let tokens: String = aexelAtts["elseChain"] as? String { aexelAtts["elseChain"] = "Gt\(no).else::\(tokens)" }
                        case "cron":
                            if let tokens: String = aexelAtts["startChain"] as? String { aexelAtts["startChain"] = "Cr\(no).start::\(tokens)" }
                            if let tokens: String = aexelAtts["stopChain"] as? String { aexelAtts["stopChain"] = "Cr\(no).stop::\(tokens)" }
                            if let tokens: String = aexelAtts["stepsChain"] as? String { aexelAtts["stepsChain"] = "Cr\(no).steps::\(tokens)" }
                            if let tokens: String = aexelAtts["rateChain"] as? String { aexelAtts["rateChain"] = "Cr\(no).rate::\(tokens)" }
                            if let tokens: String = aexelAtts["deltaChain"] as? String { aexelAtts["deltaChain"] = "Cr\(no).delta::\(tokens)" }
                            if let tokens: String = aexelAtts["whileChain"] as? String { aexelAtts["whileChain"] = "Cr\(no).while::\(tokens)" }
                        case "mech":
                            if let tokens: String = aexelAtts["resultChain"] as? String { aexelAtts["resultChain"] = "Me\(no).result::\(tokens)" }
                        case "tail":
                            if let tokens: String = aexelAtts["whileChain"] as? String { aexelAtts["whileChain"] = "Ta\(no).while::\(tokens)" }
                            if let tokens: String = aexelAtts["resultChain"] as? String { aexelAtts["resultChain"] = "Ta\(no).result::\(tokens)" }
                            if var subArray: [[String:Any]] = aexelAtts["vertebras"] as? [[String:Any]] {
                                for (subIndex, var subAtts): (Int, [String:Any]) in subArray.enumerated() {
                                    guard let subNo: Int = subAtts["no"] as? Int else { continue }
                                    if let tokens: String = subAtts["chain"] as? String { subAtts["chain"] = "Ta\(no).v\(subNo).result::\(tokens)" }
                                    subArray[subIndex] = subAtts
                                }
                                aexelAtts["vertebras"] = subArray
                            }
                        case "grid":
                            if var subArray: [[String:Any]] = aexelAtts["columns"] as? [[String:Any]] {
                                var colNo: Int = 0
                                for (subIndex, var subAtts): (Int, [String:Any]) in subArray.enumerated() {
                                    guard let subNo: Int = subAtts["no"] as? Int else { continue }
                                    if let tokens: String = subAtts["chain"] as? String { subAtts["chain"] = "cl:Gr\(no).Co\(subNo)::\(tokens)" }
                                    
                                    var newCellNo: Int = 1
                                    if let cellArray: [[String:Any]] = aexelAtts["cells"] as? [[String:Any]] {
                                        var filteredArray: [[String:Any]] = []
                                        for var cellAtts: [String:Any] in cellArray {
                                            guard let cellNo: Int = cellAtts["no"] as? Int,
                                                  cellAtts["colNo"] as! Int == colNo
                                            else { continue }
                                            cellAtts["no"] = newCellNo
                                            if let tokens: String = cellAtts["chain"] as? String { cellAtts["chain"] = "Gr\(no).Co\(subNo).Ce\(newCellNo)::\(tokens)" }
                                            filteredArray.append(cellAtts)
                                            subs.append(Subs(from: "Gr\(no).Ce\(cellNo)", to: "Gr\(no).Co\(subNo).Ce\(newCellNo)"))
                                            newCellNo += 1
                                        }
                                        subAtts["cells"] = filteredArray
                                        colNo += 1
                                    }
                                    
                                    subArray[subIndex] = subAtts
                                }
                                aexelAtts["columns"] = subArray
                                aexelAtts["cells"] = nil
                            }
                        default: break
                    }
                    aexelArray[index] = aexelAtts
                }
                attributes["aexels"] = aexelArray
            }
            
            attributes = attributes.modify(query: chainNames, convert: { (value: Any) in
                Migrate.migrateChainTo31(value as! String, subs: subs)
            })
        }

        return attributes.toJSON()
	}
}

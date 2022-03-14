//
//  Migrate.swift
//  Oovium
//
//  Created by Joe Charlier on 12/31/16.
//  Copyright © 2016 Aepryus Software. All rights reserved.
//

import Acheron
import Foundation

public class Migrate {
	public static func migrateChain(_ from: Any?, colToGrid: [Int:Int], cellToGrid: [Int:Int]) -> String? {
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
			if type == 4 && tag.loc(of: ".") == nil && tag != "k" {
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
			} else if type == TokenType.operator.rawValue && tag == "&" {
				sb += "&&"
			} else if type == TokenType.operator.rawValue && tag == "|" {
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
					jsonAtts["chain"] = migrateChain(xmlAtts["tokens"], colToGrid: colToGrid, cellToGrid: cellToGrid)
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
					jsonAtts["ifChain"] = migrateChain(xmlAtts["ifString"], colToGrid: colToGrid, cellToGrid: cellToGrid)
					jsonAtts["thenChain"] = migrateChain(xmlAtts["thenString"], colToGrid: colToGrid, cellToGrid: cellToGrid)
					jsonAtts["elseChain"] = migrateChain(xmlAtts["elseString"], colToGrid: colToGrid, cellToGrid: cellToGrid)
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
					jsonAtts["resultChain"] = migrateChain(xmlAtts["tokens"], colToGrid: colToGrid, cellToGrid: cellToGrid)
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
					jsonAtts["whileChain"] = migrateChain(xmlAtts["condition"], colToGrid: colToGrid, cellToGrid: cellToGrid)
					jsonAtts["resultChain"] = migrateChain(xmlAtts["result"], colToGrid: colToGrid, cellToGrid: cellToGrid)
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
								jsonAtts2["chain"] = migrateChain(xmlAtts2["tokens"], colToGrid: colToGrid, cellToGrid: cellToGrid)
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
								jsonAtts2["chain"] = migrateChain(xmlAtts2["tokens"], colToGrid: colToGrid, cellToGrid: cellToGrid)
								jsonAtts2["aggregate"] = xmlAtts2["aggregate"]
								let oldJustify: Int = Int(xmlAtts2["justify"] as! String)!
								jsonAtts2["justify"] = oldJustify == 0 ? 1 : (oldJustify == 1 ? 2 : 0)
								jsonAtts2["format"] = xmlAtts2["format"]
								columnArray.append(jsonAtts2)
								colIDtoColNo[jsonAtts2["no"] as! Int] = colNo
								colNo += 1
							} else if xmlAtts2["type"] as! String == "cell" {
								var jsonAtts2: [String:Any] = [:]
								jsonAtts2["iden"] = UUID().uuidString
								jsonAtts2["no"] = Int(xmlAtts2["cellID"] as! String)
								jsonAtts2["type"] = "cell"
								jsonAtts2["colNo"] = colIDtoColNo[Int(xmlAtts2["colID"] as! String)!]!
								jsonAtts2["rowNo"] = Int(xmlAtts2["rowNo"] as! String)
								jsonAtts2["chain"] = migrateChain(xmlAtts2["tokens"], colToGrid: colToGrid, cellToGrid: cellToGrid)
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
					jsonAtts["startChain"] = migrateChain(xmlAtts["start"], colToGrid: colToGrid, cellToGrid: cellToGrid)
					jsonAtts["stopChain"] = migrateChain(xmlAtts["stop"], colToGrid: colToGrid, cellToGrid: cellToGrid)
					jsonAtts["stepsChain"] = migrateChain(xmlAtts["steps"], colToGrid: colToGrid, cellToGrid: cellToGrid)
					jsonAtts["rateChain"] = migrateChain(xmlAtts["rate"], colToGrid: colToGrid, cellToGrid: cellToGrid)
					jsonAtts["deltaChain"] = migrateChain(xmlAtts["delta"], colToGrid: colToGrid, cellToGrid: cellToGrid)
					jsonAtts["whileChain"] = migrateChain(xmlAtts["whyle"], colToGrid: colToGrid, cellToGrid: cellToGrid)
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
					jsonAtts["shape"] = xmlAtts["shape"]
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
	public static func migrateAether(json: String) -> String {
		let attributes: [String:Any] = json.toAttributes()
		let version: String = attributes["version"] as? String ?? "2.0.2"

		guard version != Aether.engineVersion else { return json }
		var json = json

		print("migrate file from [\(version)] to [\(Aether.engineVersion)]")

		if version == "2.0.2" {
			let modified = attributes.modify(query:
				["chain",
				 "ifChain", "thenChain", "elseChain",
				 "resultChain", "whileChain",
				 "startChain", "stopChain", "stepChain", "rateChain", "deltaChain",
				 "statesChain", "amorousChain"
				],
			convert: { (value: Any) in
				(value as! String).replacingOccurrences(of: "1:!;", with: "8:!;").replacingOccurrences(of: "1:-;", with: "8:-;")
			})
			json = modified.toJSON()
		}

		return json
	}
}

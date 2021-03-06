//
//  MathTests.swift
//  OoviumEngineTests
//
//  Created by Joe Charlier on 10/1/16.
//  Copyright © 2016 Aepryus Software. All rights reserved.
//

import Aegean
import Acheron
@testable import OoviumEngine
import XCTest

extension Obj: Equatable {
	public static func == (lhs: Obj, rhs: Obj) -> Bool {
		guard lhs.type == rhs.type else { return false }
		switch lhs.type {
			case AETypeReal:	return lhs.a.x == rhs.a.x
			case AETypeComplex:	return lhs.a.x == rhs.a.x && lhs.b.x == rhs.b.x
			case AETypeString:	return Def.format(obj: lhs) == Def.format(obj: rhs)
			default:			return lhs.a.x == rhs.a.x && lhs.b.x == rhs.b.x && lhs.c.x == rhs.c.x
		}
	}
}

class MathTests: XCTestCase {

	override func setUp() {
		super.setUp()
		Math.start()
		Loom.namespaces = ["OoviumEngine"]
	}

	func test_Chain() {
		let zero: Obj = AEObjReal(0)

		var chain: Chain = Chain()
		chain.post(token: Token.eight)
		chain.post(token: Token.nine)
		chain.post(token: Token.three)
		chain.post(token: Token.divide)
		chain.post(token: Token.one)
		chain.post(token: Token.nine)
		XCTAssertEqual(chain.calculate() ?? zero, AEObjReal(47))

		chain = Chain(natural: "893/19")
		XCTAssertEqual(chain.calculate() ?? zero, AEObjReal(47))

		chain = Chain(natural: "798+456*12-76/19")
		XCTAssertEqual(chain.calculate() ?? zero, AEObjReal(6266))

		chain = Chain(natural: "(5^2+12^2)*7")
		XCTAssertEqual(chain.calculate() ?? zero, AEObjReal(1183))

		chain = Chain(natural: "sin(1)+cos(1)")
		XCTAssertEqual(chain.calculate() ?? zero, AEObjReal(sin(1)+cos(1)))

		chain = Chain(natural: "min(tan(1),cot(1))")
		XCTAssertEqual(chain.calculate() ?? zero, AEObjReal(min(tan(1), 1/tan(1))))

		chain = Chain(natural: "max(tan(1),cot(1))")
		XCTAssertEqual(chain.calculate() ?? zero, AEObjReal(max(tan(1), 1/tan(1))))

		chain = Chain(natural: "tan(1)")
		XCTAssertEqual(chain.calculate() ?? zero, AEObjReal(tan(1)))

		chain = Chain(natural: "cot(1)")
		XCTAssertEqual(chain.calculate() ?? zero, AEObjReal(1/tan(1)))

		chain = Chain(natural: "-4-5")
		XCTAssertEqual(chain.calculate() ?? zero, AEObjReal(-4-5))

		chain = Chain(natural: "e^(i*π)")
		XCTAssertEqual((chain.calculate() ?? zero).a.x, -1)

		chain = Chain(natural: "(3+7*i)*7*i")
		XCTAssertEqual(chain.calculate() ?? zero, AEObjComplex(-49, 21))

		chain = Chain(natural: "3+\"みどり\"")
		XCTAssertEqual(chain.calculate() ?? zero, AEObjString("3みどり".toInt8()))

		chain = Chain(natural: "Vector(1,2,3)")
		XCTAssertEqual(chain.calculate() ?? zero, AEObjVector(1, 2, 3))
	}
	func test_AetherManual() {
		let aether: Aether = Aether()

		let object1: Object = aether.createObject(at: V2.zero)
		object1.chain.replaceWith(natural: "893")

		let object2: Object = aether.createObject(at: V2.zero)
		object2.chain.replaceWith(natural: "19")

		let object3: Object = aether.createObject(at: V2.zero)
		object3.chain.post(token: object1.token)
		object3.chain.post(token: Token.divide)
		object3.chain.post(token: object2.token)

		aether.buildTokens()
		aether.evaluate()
		XCTAssertEqual(object3.chain.tower.value, 47)
	}
	func test_AetherJSONBasic() {
		let json = """
			{
			  "height" : 0,
			  "iden" : "10F334FA-0A7C-4247-AF36-363ABF08CBB4",
			  "yOffset" : 0,
			  "aexels" : [
				{
				  "iden" : "194E1426-4A32-4D13-8FA5-B5420E8DB6A0",
				  "name" : "Ob_1",
				  "no" : 1,
				  "chain" : "0:8;0:9;0:3",
				  "label" : "",
				  "type" : "object",
				  "y" : 0,
				  "x" : 0
				},
				{
				  "x" : 0,
				  "y" : 0,
				  "type" : "object",
				  "iden" : "5D7FFBA3-8E8B-4245-855A-82F6044F6E29",
				  "name" : "Ob_2",
				  "chain" : "0:1;0:9",
				  "no" : 2,
				  "label" : ""
				},
				{
				  "y" : 0,
				  "name" : "Ob_3",
				  "x" : 0,
				  "label" : "",
				  "type" : "object",
				  "chain" : "4:Ob_1;1:÷;4:Ob_2",
				  "iden" : "465775B6-5243-4269-86CB-1601B39C0F7A",
				  "no" : 3
				}
			  ],
			  "type" : "aether",
			  "name" : "aether01",
			  "readOnly" : false,
			  "modified" : "2021-03-07T15:23:13+0900",
			  "width" : 0,
			  "xOffset" : 0
			}
		"""

		let aether = Aether()
		aether.load(attributes: json.toAttributes())

		let object: Object = aether.aexel(type: "object", no: 3) as! Object
		XCTAssertEqual(object.chain.tower.value, 47)
	}
	func test_AetherJSONTail() {
		let json = """
			{
			  "name" : "Cat Skin",
			  "aexels" : [
				{
				  "iden" : "16AD75B7-27F0-4B34-A611-00DA150411D1",
				  "type" : "mech",
				  "name" : "TSF",
				  "modified" : "2021-03-07T23:05:00+0900",
				  "no" : 1,
				  "inputs" : [
					{
					  "type" : "input",
					  "name" : "n",
					  "modified" : "2021-03-07T23:05:00+0900",
					  "iden" : "FA5AED43-38D0-4B9F-8C93-9A37778FE1EC"
					}
				  ],
				  "resultChain" : "3:iTSF;4:TSF.n;2:,;0:2;2:)",
				  "x" : 1676.765625,
				  "y" : 1263.5390625
				},
				{
				  "vertebras" : [
					{
					  "name" : "n",
					  "chain" : "4:iTSF.n",
					  "modified" : "2021-03-07T23:04:14+0900",
					  "iden" : "A819C130-6DBA-4CA7-A359-D819E3C69C04",
					  "type" : "vertebra"
					},
					{
					  "iden" : "D1C1A3E8-5B68-4DF6-9433-F4E9B2DEC969",
					  "type" : "vertebra",
					  "modified" : "2021-03-07T23:04:52+0900",
					  "chain" : "4:iTSF.p;1:+;0:1",
					  "name" : "p"
					}
				  ],
				  "whileChain" : "8:!;4:Ob_2;1:&&;8:!;4:Ob_1",
				  "no" : 1,
				  "y" : 1059.96484375,
				  "modified" : "2021-03-07T23:04:52+0900",
				  "iden" : "B21944AB-6A7C-4CA4-8CE2-54981FAF557A",
				  "name" : "iTSF",
				  "x" : 1685.8359375,
				  "resultChain" : "4:GtR_1",
				  "type" : "tail"
				},
				{
				  "no" : 1,
				  "name" : "Ob_1",
				  "x" : 1967.30859375,
				  "y" : 1038,
				  "type" : "object",
				  "chain" : "2:(;4:iTSF.p;1:+;0:1;2:);1:×;2:(;4:iTSF.p;1:+;0:1;2:);1:>;4:iTSF.n",
				  "label" : "prime",
				  "iden" : "094D10F0-B553-4012-93C4-A0CF8AF7B455"
				},
				{
				  "y" : 1129.9375,
				  "name" : "Ob_2",
				  "no" : 2,
				  "x" : 2021.51171875,
				  "type" : "object",
				  "label" : "factor",
				  "chain" : "2:(;4:iTSF.n;1:÷;4:iTSF.p;2:);1:=;3:floor;4:iTSF.n;1:÷;4:iTSF.p;2:)",
				  "iden" : "25C46F80-0A51-4655-9638-60C6FA25B47F"
				},
				{
				  "name" : "Ob_3",
				  "type" : "object",
				  "no" : 3,
				  "y" : 1275.54296875,
				  "iden" : "D7EEF462-F6CE-431B-86BB-235ACBC3C0CB",
				  "x" : 1281,
				  "label" : "",
				  "chain" : "0:8;0:9;0:3"
				},
				{
				  "y" : 1258.2890625,
				  "type" : "gate",
				  "name" : "",
				  "no" : 1,
				  "iden" : "E8B55187-1382-4AE3-B83C-22A7B6E69185",
				  "elseChain" : "4:iTSF.n",
				  "x" : 2005.12109375,
				  "thenChain" : "4:iTSF.p",
				  "ifChain" : "4:Ob_2"
				},
				{
				  "chain" : "3:TSF;4:Ob_3;2:)",
				  "type" : "object",
				  "no" : 4,
				  "label" : "TSF",
				  "name" : "Ob_4",
				  "y" : 1179.6484375,
				  "x" : 1397.5655937500001,
				  "iden" : "426D1E54-0D35-44B2-A71E-3C3F5D290017"
				}
			  ],
			  "xOffset" : 896,
			  "type" : "aether",
			  "readOnly" : false,
			  "height" : 1046,
			  "modified" : "2021-03-07T23:11:08+0900",
			  "iden" : "5E90C7D8-347D-4C96-AD98-6A45D424B155",
			  "width" : 1333,
			  "yOffset" : 772
			}
		"""

		let aether = Aether()
		aether.load(attributes: json.toAttributes())

		let object = aether.aexel(type: "object", no: 4) as! Object
		XCTAssertEqual(object.chain.tower.value, 19)
	}
}

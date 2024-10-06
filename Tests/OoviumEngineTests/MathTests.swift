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

extension Obj: @retroactive Equatable {
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
        chain.post(key: Token.eight.key)
		chain.post(key: Token.nine.key)
		chain.post(key: Token.three.key)
		chain.post(key: Token.divide.key)
		chain.post(key: Token.one.key)
		chain.post(key: Token.nine.key)
        var chainExe: ChainCore = chain.compile()
		XCTAssertEqual(chainExe.calculate() ?? zero, AEObjReal(47))

		chain = Chain(natural: "893/19")
        chainExe = chain.compile()
		XCTAssertEqual(chainExe.calculate() ?? zero, AEObjReal(47))

		chain = Chain(natural: "798+456*12-76/19")
        chainExe = chain.compile()
		XCTAssertEqual(chainExe.calculate() ?? zero, AEObjReal(6266))

		chain = Chain(natural: "(5^2+12^2)*7")
        chainExe = chain.compile()
		XCTAssertEqual(chainExe.calculate() ?? zero, AEObjReal(1183))

		chain = Chain(natural: "sin(1)+cos(1)")
        chainExe = chain.compile()
		XCTAssertEqual(chainExe.calculate() ?? zero, AEObjReal(sin(1)+cos(1)))

		chain = Chain(natural: "min(tan(1),cot(1))")
        chainExe = chain.compile()
		XCTAssertEqual(chainExe.calculate() ?? zero, AEObjReal(min(tan(1), 1/tan(1))))

		chain = Chain(natural: "max(tan(1),cot(1))")
        chainExe = chain.compile()
		XCTAssertEqual(chainExe.calculate() ?? zero, AEObjReal(max(tan(1), 1/tan(1))))

		chain = Chain(natural: "tan(1)")
        chainExe = chain.compile()
		XCTAssertEqual(chainExe.calculate() ?? zero, AEObjReal(tan(1)))

		chain = Chain(natural: "cot(1)")
        chainExe = chain.compile()
		XCTAssertEqual(chainExe.calculate() ?? zero, AEObjReal(1/tan(1)))

		chain = Chain(natural: "-4-5")
        chainExe = chain.compile()
		XCTAssertEqual(chainExe.calculate() ?? zero, AEObjReal(-4-5))

		chain = Chain(natural: "e^(i*π)")
        chainExe = chain.compile()
		XCTAssertEqual((chainExe.calculate() ?? zero).a.x, -1)

		chain = Chain(natural: "(3+7*i)*7*i")
        chainExe = chain.compile()
		XCTAssertEqual(chainExe.calculate() ?? zero, AEObjComplex(-49, 21))

		chain = Chain(natural: "3+\"みどり\"")
        chainExe = chain.compile()
		XCTAssertEqual(chainExe.calculate() ?? zero, AEObjString("3みどり".toInt8()))

		chain = Chain(natural: "Vector(1,2,3)")
        chainExe = chain.compile()
		XCTAssertEqual(chainExe.calculate() ?? zero, AEObjVector(1, 2, 3))
	}
	func test_AetherManual() {
		let aether: Aether = Aether()

		let object1: Object = aether.create(at: V2.zero)
		object1.chain.replaceWith(natural: "893")

		let object2: Object = aether.create(at: V2.zero)
		object2.chain.replaceWith(natural: "19")

		let object3: Object = aether.create(at: V2.zero)
        object3.chain.post(key: object1.chain.key!)
        object3.chain.post(key: Token.divide.key)
        object3.chain.post(key: object2.chain.key!)
        
        let aetherExe: AetherExe = aether.compile()

        let key = TokenKey(code: .va, tag: object3.key)
        let tower = aetherExe.tower(key: key)!
		XCTAssertEqual(tower.value, 47)
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
				  "name" : "",
				  "no" : 1,
				  "chain" : "Ob1::dg:8;dg:9;dg:3",
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
				  "name" : "",
				  "chain" : "Ob2::dg:1;dg:9",
				  "no" : 2,
				  "label" : ""
				},
				{
				  "y" : 0,
				  "name" : "",
				  "x" : 0,
				  "label" : "",
				  "type" : "object",
				  "chain" : "Ob3::va:Ob1;op:÷;va:Ob2",
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

		let aether = Aether(json: json)
        let aetherExe: AetherExe = aether.compile()
        let key: TokenKey = TokenKey(code: .va, tag: "Ob3")
        XCTAssertEqual(aetherExe.tower(key: key)?.value, 47)
	}
	func test_AetherJSONCatSkinTSF() {
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
                      "no" : 1,
                      "modified" : "2021-03-07T23:05:00+0900",
                      "iden" : "FA5AED43-38D0-4B9F-8C93-9A37778FE1EC"
                    }
                  ],
                  "resultChain" : "Me1.result::ml:Ta1;va:Me1.i1;sp:,;dg:2;sp:)",
                  "x" : 1676.765625,
                  "y" : 1263.5390625
                },
                {
                  "vertebras" : [
                    {
                      "name" : "n",
                      "no" : 1,
                      "chain" : "Ta1.v1.result::va:Ta1.v1",
                      "modified" : "2021-03-07T23:04:14+0900",
                      "iden" : "A819C130-6DBA-4CA7-A359-D819E3C69C04",
                      "type" : "vertebra"
                    },
                    {
                      "iden" : "D1C1A3E8-5B68-4DF6-9433-F4E9B2DEC969",
                      "type" : "vertebra",
                      "modified" : "2021-03-07T23:04:52+0900",
                      "chain" : "Ta1.v2.result::va:Ta1.v2;op:+;dg:1",
                      "no" : 2,
                      "name" : "p"
                    }
                  ],
                  "whileChain" : "Ta1.while::un:!;va:Ob2;op:&&;un:!;va:Ob1",
                  "no" : 1,
                  "y" : 1059.96484375,
                  "modified" : "2021-03-07T23:04:52+0900",
                  "iden" : "B21944AB-6A7C-4CA4-8CE2-54981FAF557A",
                  "name" : "iTSF",
                  "x" : 1685.8359375,
                  "resultChain" : "Ta1.result::va:Gt1",
                  "type" : "tail"
                },
                {
                  "no" : 1,
                  "name" : "",
                  "x" : 1967.30859375,
                  "y" : 1038,
                  "type" : "object",
                  "chain" : "Ob1::sp:(;va:Ta1.v2;op:+;dg:1;sp:);op:×;sp:(;va:Ta1.v2;op:+;dg:1;sp:);op:>;va:Ta1.v1",
                  "label" : "prime",
                  "iden" : "094D10F0-B553-4012-93C4-A0CF8AF7B455"
                },
                {
                  "y" : 1129.9375,
                  "name" : "",
                  "no" : 2,
                  "x" : 2021.51171875,
                  "type" : "object",
                  "label" : "factor",
                  "chain" : "Ob2::sp:(;va:Ta1.v1;op:÷;va:Ta1.v2;sp:);op:=;fn:floor;va:Ta1.v1;op:÷;va:Ta1.v2;sp:)",
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
                  "chain" : "Ob3::dg:8;dg:9;dg:3"
                },
                {
                  "y" : 1258.2890625,
                  "type" : "gate",
                  "name" : "",
                  "no" : 1,
                  "iden" : "E8B55187-1382-4AE3-B83C-22A7B6E69185",
                  "elseChain" : "Gt1.else::va:Ta1.v1",
                  "x" : 2005.12109375,
                  "thenChain" : "Gt1.then::va:Ta1.v2",
                  "ifChain" : "Gt1.if::va:Ob2"
                },
                {
                  "chain" : "Ob4::ml:Me1;va:Ob3;sp:)",
                  "type" : "object",
                  "no" : 4,
                  "label" : "TSF",
                  "name" : "",
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

        let aether = Aether(json: json)
        let aetherExe: AetherExe = aether.compile()
        let key: TokenKey = TokenKey(code: .va, tag: "Ob4")
        XCTAssertEqual(aetherExe.tower(key: key)?.value, 19)
	}
    func test_AetherJSONCatSkinISF() {
        let json = """
            {
              "type" : "aether",
              "xOffset" : 1000,
              "readOnly" : false,
              "width" : 1194,
              "name" : "aether41",
              "version" : "3.0",
              "modified" : "2022-08-30T05:19:54+0900",
              "height" : 834,
              "yOffset" : 706,
              "aexels" : [
                {
                  "resultChain" : "Me1.result::ml:Me2;va:Me1.i1;sp:,;dg:2;sp:)",
                  "type" : "mech",
                  "modified" : "2022-08-29T16:58:02+0900",
                  "x" : 1689.5,
                  "name" : "ISF",
                  "y" : 901,
                  "inputs" : [
                    {
                      "modified" : "2022-08-29T16:58:02+0900",
                      "type" : "input",
                      "name" : "n",
                      "no" : 1,
                      "iden" : "CE64A376-5305-4C0A-B1CA-15A19449050D"
                    }
                  ],
                  "iden" : "8B6ECADC-CE92-435B-AA21-C11EA448E5FA",
                  "no" : 1
                },
                {
                  "y" : 799,
                  "label" : "",
                  "iden" : "7D02A9FA-43BF-44F5-9AE4-64646FCF2FAB",
                  "no" : 4,
                  "type" : "object",
                  "name" : "Ob_4",
                  "x" : 1996,
                  "chain" : "Ob4::dg:8;dg:9;dg:3"
                },
                {
                  "iden" : "51083427-34B2-45E0-9999-23B590DE2586",
                  "label" : "",
                  "chain" : "Ob5::ml:Me1;va:Ob4;sp:)",
                  "type" : "object",
                  "y" : 884,
                  "no" : 5,
                  "name" : "Ob_5",
                  "x" : 1938
                },
                {
                  "no" : 2,
                  "type" : "mech",
                  "iden" : "A6C099FD-DFBD-483E-AD4E-35750917DE53",
                  "name" : "iISF",
                  "modified" : "2022-08-29T16:58:50+0900",
                  "y" : 976.5,
                  "resultChain" : "Me2.result::va:Gt1",
                  "x" : 1446,
                  "inputs" : [
                    {
                      "name" : "n",
                      "no" : 1,
                      "modified" : "2022-08-29T16:58:40+0900",
                      "type" : "input",
                      "iden" : "0F60515D-64B7-4CD9-9C54-927701E2EC27"
                    },
                    {
                      "iden" : "A75067BE-ACD9-42A7-B6ED-56EFFF23093A",
                      "name" : "p",
                      "no" : 2,
                      "modified" : "2022-08-29T16:58:50+0900",
                      "type" : "input"
                    }
                  ]
                },
                {
                  "iden" : "BC02BEEA-B491-450D-84E9-DD3AC2FE7438",
                  "x" : 1315.5,
                  "name" : "Ob_6",
                  "y" : 990,
                  "chain" : "Ob6::va:Me2.i1;op:÷;va:Me2.i2",
                  "no" : 6,
                  "label" : "",
                  "type" : "object"
                },
                {
                  "label" : "",
                  "x" : 1178.5,
                  "no" : 7,
                  "y" : 1043.5,
                  "chain" : "Ob7::fn:floor;va:Ob6;sp:)",
                  "iden" : "2A9115BA-3320-49A4-B7B5-9FC8953E89B1",
                  "name" : "Ob_7",
                  "type" : "object"
                },
                {
                  "y" : 1136,
                  "thenChain" : "Gt1.then::va:Me2.i2",
                  "name" : "",
                  "elseChain" : "Gt1.else::va:Gt2",
                  "no" : 1,
                  "ifChain" : "Gt1.if::va:Ob6;op:=;va:Ob7",
                  "type" : "gate",
                  "iden" : "E84E558B-7EEE-411F-93F4-395FA77D4858",
                  "x" : 1094
                },
                {
                  "type" : "gate",
                  "y" : 1219,
                  "elseChain" : "Gt2.else::ml:Me2;va:Me2.i1;sp:,;va:Me2.i2;op:+;dg:1;sp:)",
                  "thenChain" : "Gt2.then::va:Me2.i1",
                  "name" : "",
                  "no" : 2,
                  "ifChain" : "Gt2.if::va:Me2.i2;op:×;va:Me2.i2;op:>;va:Me2.i1",
                  "x" : 1400,
                  "iden" : "055C990D-5E5E-4E8C-9846-B5788BCF74CC"
                }
              ],
              "iden" : "9C29BBEE-7040-49BC-A04C-96F6F5F57EE9"
            }
        """

        let aether = Aether(json: json)
        let aetherExe: AetherExe = aether.compile()
        let key: TokenKey = TokenKey(code: .va, tag: "Ob5")
        XCTAssertEqual(aetherExe.tower(key: key)?.value, 19)
    }
    func test_AetherJSONCatSkinRSF() {
        let json = """
            {
              "xOffset" : 1014.5,
              "type" : "aether",
              "modified" : "2022-08-31T12:36:05+0900",
              "name" : "aether20",
              "width" : 1194,
              "aexels" : [
                {
                  "iden" : "E999D193-691D-4DB1-B4F3-BAEE80BB01F3",
                  "name" : "RSF",
                  "y" : 881,
                  "type" : "mech",
                  "no" : 1,
                  "resultChain" : "Me1.result::ml:Me2;va:Me1.i1;sp:,;dg:2;sp:)",
                  "modified" : "2022-08-31T12:23:15+0900",
                  "x" : 1762.75,
                  "inputs" : [
                    {
                      "type" : "input",
                      "no" : 1,
                      "iden" : "A0EB0707-6561-4044-A4A0-E7C13EFDE4D3",
                      "modified" : "2022-08-31T12:23:15+0900",
                      "name" : "n"
                    }
                  ]
                },
                {
                  "type" : "mech",
                  "iden" : "B09E5F9E-F97A-47C9-BDE2-6A8B4500EB5D",
                  "no" : 2,
                  "x" : 1360,
                  "name" : "iRSF",
                  "resultChain" : "Me2.result::va:Ob10",
                  "inputs" : [
                    {
                      "type" : "input",
                      "modified" : "2022-08-31T12:23:42+0900",
                      "iden" : "5C163365-CC14-4309-9A3D-416ADAADF044",
                      "no" : 1,
                      "name" : "n"
                    },
                    {
                      "name" : "p",
                      "no" : 2,
                      "modified" : "2022-08-31T12:23:48+0900",
                      "type" : "input",
                      "iden" : "DBDDEA1F-2E06-4E15-ABFF-2F08B9DAC05E"
                    }
                  ],
                  "modified" : "2022-08-31T12:23:48+0900",
                  "y" : 878
                },
                {
                  "y" : 799,
                  "chain" : "Ob1::dg:8;dg:9;dg:3",
                  "type" : "object",
                  "name" : "Ob_1",
                  "label" : "",
                  "no" : 1,
                  "iden" : "37BE8EC8-9A2F-4D3E-9ED1-F19951FDBA9D",
                  "x" : 2066
                },
                {
                  "name" : "Ob_2",
                  "no" : 2,
                  "y" : 879.5,
                  "type" : "object",
                  "label" : "",
                  "x" : 1972,
                  "chain" : "Ob2::ml:Me1;va:Ob1;sp:)",
                  "iden" : "475600DF-5730-4B73-899F-F817C396AADC"
                },
                {
                  "no" : 4,
                  "type" : "object",
                  "y" : 949,
                  "chain" : "Ob4::va:Me2.i1;op:÷;va:Me2.i2",
                  "iden" : "38FC6BFB-808A-4BF4-B98B-2E289864C95A",
                  "name" : "Ob_4",
                  "label" : "",
                  "x" : 1282.5
                },
                {
                  "iden" : "0E2D9022-C1E4-4972-BFA0-6D6A7B2637FF",
                  "type" : "object",
                  "name" : "Ob_5",
                  "x" : 1094,
                  "y" : 1000,
                  "no" : 5,
                  "chain" : "Ob5::fn:floor;va:Ob4;sp:)",
                  "label" : ""
                },
                {
                  "name" : "Ob_6",
                  "y" : 1077,
                  "no" : 6,
                  "x" : 1145.75,
                  "iden" : "655D064D-6FBE-4B26-8580-3C86EB22C388",
                  "label" : "isFactor",
                  "chain" : "Ob6::va:Ob5;op:=;va:Ob4",
                  "type" : "object"
                },
                {
                  "iden" : "1706384C-2E88-4D23-B6B4-635DFFD4FC40",
                  "chain" : "Ob7::sp:[;ml:Me2;va:Me2.i1;sp:,;va:Me2.i2;op:+;dg:1;sp:);sp:]",
                  "no" : 7,
                  "type" : "object",
                  "label" : "",
                  "name" : "Ob_7",
                  "x" : 1532,
                  "y" : 948.5
                },
                {
                  "chain" : "Ob8::sp:[;va:Me2.i1;sp:]",
                  "iden" : "099C5651-A594-44CF-9D17-83B52992058C",
                  "y" : 873,
                  "no" : 8,
                  "x" : 1518.25,
                  "label" : "",
                  "type" : "object",
                  "name" : "Ob_8"
                },
                {
                  "type" : "object",
                  "label" : "increment",
                  "chain" : "Ob9::fn:if;va:Me2.i2;op:×;va:Me2.i2;op:>;va:Me2.i1;sp:,;va:Ob8;sp:,;va:Ob7;sp:)",
                  "no" : 9,
                  "x" : 1429.75,
                  "y" : 1058,
                  "iden" : "CB327906-E7DE-43C3-89F3-CA036A977FD2",
                  "name" : "Ob_9"
                },
                {
                  "chain" : "Ob10::fn:if;va:Ob6;sp:,;va:Me2.i2;sp:,;va:Ob9;sp:)",
                  "no" : 10,
                  "iden" : "ACA1A70B-CA6E-4925-8897-E04F52A7A20A",
                  "y" : 1159,
                  "label" : "result",
                  "x" : 1255.25,
                  "type" : "object",
                  "name" : "Ob_10"
                }
              ],
              "yOffset" : 666,
              "version" : "3.0",
              "readOnly" : false,
              "iden" : "E3BB4A35-F906-44BD-B7ED-89AAB42D3AB2",
              "height" : 834
            }
        """

        let aether = Aether(json: json)
        let aetherExe: AetherExe = aether.compile()
        let key: TokenKey = TokenKey(code: .va, tag: "Ob2")
        XCTAssertEqual(aetherExe.tower(key: key)?.value, 19)
    }
    func test_AetherJSONSUM() {
        let json = """
            {
              "height" : 1554,
              "xOffset" : 3254,
              "version" : "3.0",
              "type" : "aether",
              "width" : 2365,
              "readOnly" : false,
              "aexels" : [
                {
                  "x" : 3476.28125,
                  "y" : 2041.30859375,
                  "iden" : "1ACDBCFF-D24E-4659-A27C-DB94D30BE152",
                  "no" : 2,
                  "name" : "Ob_2",
                  "label" : "",
                  "type" : "object",
                  "chain" : "Ob2::dg:1"
                },
                {
                  "iden" : "C2EFF853-FF8F-4AD1-A31B-CE99DD46ABF2",
                  "name" : "Ob_3",
                  "x" : 3611.0859375,
                  "type" : "object",
                  "y" : 2021.39453125,
                  "chain" : "Ob3::dg:9",
                  "label" : "",
                  "no" : 3
                },
                {
                  "type" : "object",
                  "label" : "",
                  "chain" : "Ob4::sp:[;va:k;sp:]",
                  "y" : 2102.7734375,
                  "x" : 3699.59375,
                  "iden" : "B2783579-B39E-43E9-8B28-2732A74FB2F5",
                  "no" : 4,
                  "name" : "Ob_4"
                },
                {
                  "iden" : "9DABA2E8-4797-48DB-928F-3826EFA4F482",
                  "type" : "object",
                  "chain" : "Ob5::fn:∑;va:Ob2;sp:,;va:Ob3;sp:,;va:Ob4;sp:)",
                  "name" : "Ob_5",
                  "x" : 3545.046875,
                  "no" : 5,
                  "label" : "",
                  "y" : 2157.28125
                }
              ],
              "iden" : "0CE1804D-CB3E-475B-827C-C7524505E6B4",
              "yOffset" : 2077.5,
              "modified" : "2022-08-30T19:44:55+0900",
              "name" : "aether05"
            }
        """
        
        let aether = Aether(json: json)
        let aetherExe: AetherExe = aether.compile()
        let key: TokenKey = TokenKey(code: .va, tag: "Ob5")
        XCTAssertEqual(aetherExe.tower(key: key)?.value, 45)
    }
}

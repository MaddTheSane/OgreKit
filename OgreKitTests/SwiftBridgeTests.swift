//
//  SwiftBridgeTests.swift
//  OgreKit
//
//  Created by C.W. Betts on 5/30/15.
//
//

import Cocoa
import XCTest
import OgreKit

class SwiftBridgeTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testCaptureTree() {
        var		expr = "(1+2)*3+4";
        let		calc = SwiftCalc()
        var     evaled: Double = calc.eval(expr) ?? 0
        XCTAssertEqual(evaled, 13, "\(expr) != 13! (actual value \(evaled)")
        
        expr = "36.5*9/5+32";
        evaled = calc.eval(expr) ?? Double(0.0)
        XCTAssertEqual(evaled, 97.7, "\(expr) != 97.7! (actual value \(evaled)")
    }
	
	/// Substituted entrusted the process to delegate / matched split in part (デリゲートに処理を委ねた置換／マッチした部分での分割)
	func testReplace() {
		NSLog("Replacement Test")
		let regex = OGRegularExpression(string: "a*")!
		let matcher = regex.matchEnumeratorInString("aaaaaaa", range: NSRange(location: 1, length: 3))
		for preMatch in matcher {
			let match = preMatch as! OGRegularExpressionMatch
			let matchRange = match.rangeOfMatchedString
			NSLog("(\(matchRange.location), \(matchRange.length))")
		}
	}
	
	/// Substitution was entrusted with processing to delegate (デリゲートに処理を委ねた置換)
	func testSubstitution() {
		let targetString = "36.5C, 3.8C, -195.8C"
		println(targetString)
		let celciusRegex = OGRegularExpression(string: "([+-]?\\d+(?:\\.\\d+)?)C\\b")!
		let logString = celciusRegex.replaceAllMatchesInString(targetString, delegate: self, replaceSelector: "fahrenheitFromCelsius:contextInfo:", contextInfo: nil)
		XCTAssertEqual(logString, "97.7F, 38.8F, -320.4F");
	}
	
	/// Splits a string (文字列を分割する)
	func testSplit() {
		let targetString = "36.5C, 3.8C, -195.8C"
		let delimiterRegex = OGRegularExpression(string: "\\s*,\\s*")!
		let split = delimiterRegex.splitString(targetString) as! [String]
		let expected: [String] = ["36.5C", "3.8C", "-195.8C"]
		XCTAssertEqual(split, expected, "Split expected to be \(expected.description), but returned \(split.description)")
	}
	
	func testCategory() {
		let string: NSString = "36.5C, 3.8C, -195.8C";
		//println(string.componentsSeparatedByRegularExpressionString("\\s*,\\s*").description)
		let mstr = NSMutableString(string: string)
		let numberOfReplacement = mstr.replaceOccurrencesOfRegularExpressionString("C",
			withString: "F", options: OgreNoneOption, range: NSMakeRange(0, string.length))
		println("\(numberOfReplacement) \(mstr)");
		let matchRange = string.rangeOfRegularExpressionString("\\s*,\\s*")
		println("(\(matchRange.location), \(matchRange.length))")
	}
	
	/// Converts Celsius to Fahrenheit. (摂氏を華氏に変換する。)
	@objc private func fahrenheitFromCelsius(aMatch: OGRegularExpressionMatch, contextInfo: AnyObject?) -> String {
		if let matched = aMatch.substringAtIndex(1) {
			let celcius = (matched as NSString).doubleValue
			let fahrenheit = celcius * 9.0 / 5.0 + 32.0
			
			// return the replaced string. to terminate the substitution if it returns nil. (置換した文字列を返す。nilを返した場合は置換を終了する。)
			return String(format: "%.1fF", fahrenheit)
		} else {
			return "0F"
		}
	}

}

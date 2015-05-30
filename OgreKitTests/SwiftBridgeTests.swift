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
}

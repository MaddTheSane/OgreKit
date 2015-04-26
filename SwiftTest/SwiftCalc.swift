//
//  SwiftCalc.swift
//  OgreKit
//
//  Created by C.W. Betts on 4/25/15.
//
//

import Cocoa
import OgreKit

private let calcRegex = "\\g<e>(?<e>\\g<t>(?:(?@<e1>\\+\\g<t>)|(?@<e2>\\-\\g<t>))*){0}(?<t>\\g<f>(?:(?@<t1>\\*\\g<f>)|(?@<t2>/\\g<f>))*){0}(?<f>\\(\\g<e>\\)|(?@<f2>\\d+(?:\\.\\d*)?)){0}"

final class SwiftCalc: NSObject, OGRegularExpressionCaptureVisitor {
	var stack = [Double]()
	
	func visitAtFirstCapture(aCapture: OGRegularExpressionCapture!) {
		
	}
	
	func visitAtLastCapture(aCapture: OGRegularExpressionCapture!) {
		if let name = aCapture.groupName {
			switch name {
			case "e1":
				reduce_e1(aCapture)
				
			case "t1":
				reduce_t1(aCapture)
				
			case "f2":
				reduce_f2(aCapture)
				
			case "t2":
				reduce_t2(aCapture)
				
			case "e2":
				reduce_e2(aCapture)
				
			default:
				return
			}
			
			NSLog("Stack: %@ <%@>", stack.description, name);
		}
	}
	
	func push(item: Double) {
		stack.append(item)
	}
	
	func pop() -> Double? {
		if stack.count == 0 {
			return nil
		}
		
		let anObject = stack.last!
		stack.removeAtIndex(stack.count - 1)
		
		return anObject
	}
	
	func eval(expression: String) -> Double? {
		let regex = OGRegularExpression(string: calcRegex, options: OgreCaptureGroupOption, syntax: .RubySyntax, escapeCharacter: OgreBackslashCharacter)
		let match = regex.matchInString(expression)
		
		if match == nil || match.rangeOfMatchedString.length != count(expression) {
			return nil
		}
		
		match.captureHistory.acceptVisitor(self)
		return pop()
	}
	
	private func reduce_e1(aCapture: OGRegularExpressionCapture) {
		if let num2 = pop(), num1 = pop() {
			push(num1 + num2)
		}
	}
	
	private func reduce_t1(aCapture: OGRegularExpressionCapture) {
		if let num2 = pop(), num1 = pop() {
			push(num1 * num2)
		}
	}
	
	private func reduce_f2(aCapture: OGRegularExpressionCapture) {
		push((aCapture.string as NSString).doubleValue)
	}

	private func reduce_e2(aCapture: OGRegularExpressionCapture) {
		if let num2 = pop(), num1 = pop() {
			push(num1 - num2)
		}
	}
	
	private func reduce_t2(aCapture: OGRegularExpressionCapture) {
		if let num2 = pop(), num1 = pop() {
			push(num1 / num2)
		}
	}
}

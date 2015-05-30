//
//  AppDelegate.swift
//  SwiftTest
//
//  Created by C.W. Betts on 4/25/15.
//
//

import Cocoa
import OgreKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, OGRegularExpressionCaptureVisitor {
	@IBOutlet weak var window: NSWindow!
	@IBOutlet weak var replaceTextField: NSTextField!
	@IBOutlet weak var patternTextField: NSTextField!
	@IBOutlet weak var resultScrollView: NSScrollView!
	@IBOutlet weak var targetTextField: NSTextField!
	@IBOutlet weak var escapeCharacterTextField: NSTextField!

	var resultTextView: NSTextView! {
		return resultScrollView.documentView as? NSTextView
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		resultTextView.richText = false
		resultTextView.font = NSFont(name: "Monaco", size: 10.0)
		resultTextView.continuousSpellCheckingEnabled = false
		
		replaceTest()
		categoryTest()
		captureTreeTest()
	}
	
	private func captureTreeTest() {
		println("Capture Tree Test");
		var		expr = "(1+2)*3+4";
		let		calc = SwiftCalc()
		println("\(expr) = \(calc.eval(expr)!)");
		
		expr = "36.5*9/5+32";
		println("\(expr) = \(calc.eval(expr)!)");
	}

	/// Substituted entrusted the process to delegate / matched split in part (デリゲートに処理を委ねた置換／マッチした部分での分割)
	private func replaceTest() {
		NSLog("Replacement Test")
		let regex = OGRegularExpression(string: "a*")!
		let matcher = regex.matchEnumeratorInString("aaaaaaa", range: NSRange(location: 1, length: 3))
		for preMatch in matcher {
			let match = preMatch as! OGRegularExpressionMatch
			let matchRange = match.rangeOfMatchedString
			NSLog("(\(matchRange.location), \(matchRange.length))")
		}
		
		// Substitution was entrusted with processing to delegate (デリゲートに処理を委ねた置換)
		let targetString = "36.5C, 3.8C, -195.8C"
		println(targetString)
		let celciusRegex = OGRegularExpression(string: "([+-]?\\d+(?:\\.\\d+)?)C\\b")!
		let logString = celciusRegex.replaceAllMatchesInString(targetString, delegate: self, replaceSelector: "fahrenheitFromCelsius:contextInfo:", contextInfo: nil)
		println(logString)
		
		// Splits a string (文字列を分割する)
		let delimiterRegex = OGRegularExpression(string: "\\s*,\\s*")!
		println(delimiterRegex.splitString(targetString))
	}

	private func categoryTest() {
		println("NSString (OgreKitAdditions) Test");
		let string: NSString = "36.5C, 3.8C, -195.8C";
		println(string.componentsSeparatedByRegularExpressionString("\\s*,\\s*").description)
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
	
	@IBAction func match(sender: AnyObject?) {
		
	}
	
	@IBAction func replace(sender: AnyObject?) {
		
	}
	
	func applicationDidFinishLaunching(aNotification: NSNotification) {
		// Insert code here to initialize your application
	}
	
	func applicationWillTerminate(aNotification: NSNotification) {
		// Insert code here to tear down your application
	}
	
	func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
		return true
	}
	
	func visitAtFirstCapture(aCapture: OGRegularExpressionCapture?) {
		if let aCapture = aCapture {
			var indent = ""
			for i in 0 ..< aCapture.level {
				indent += "  "
			}
			var matchRange = aCapture.range
			
			/*NSLog(@"capture: %@", [aCapture description]);
			[NSArchiver archiveRootObject:aCapture toFile: [@"~/Desktop/cap.archive" stringByExpandingTildeInPath]];
			OGRegularExpressionCapture	*capture2 = [NSUnarchiver unarchiveObjectWithFile: [@"~/Desktop/cap.archive" stringByExpandingTildeInPath]];
			NSLog(@"capture2: %@", [capture2 description]);
			aCapture = capture2;*/
			
			resultTextView.insertText(String(format: " %@#%lu", indent, aCapture.groupIndex))
			if let groupName = aCapture.groupName {
				resultTextView.insertText("(\"\(groupName)\")")
			}
			resultTextView.insertText(": (\(matchRange.location)-\(matchRange.length)) \"\(aCapture.string)\"\n")
		}
	}

	func visitAtLastCapture(aCapture: OGRegularExpressionCapture?) {
		
	}
}

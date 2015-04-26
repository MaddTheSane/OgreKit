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
class AppDelegate: NSObject, NSApplicationDelegate {
	@IBOutlet weak var window: NSWindow!
	
	func applicationDidFinishLaunching(aNotification: NSNotification) {
		// Insert code here to initialize your application
		NSLog("GC Test - start");
		
		let regex = OGRegularExpression(string: "a")
		
		var count: UInt64 = 0;
		for var i = 0; i < 1000000000; i++ {
			let matcher = regex.matchEnumeratorInString("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
			for match in matcher {
				count++
			}
		}
		
		NSLog("GC Test - end");
		println(count)
	}
	
	func applicationWillTerminate(aNotification: NSNotification) {
		// Insert code here to tear down your application
	}
}


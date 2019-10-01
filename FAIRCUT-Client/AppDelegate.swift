//
//  AppDelegate.swift
//  FAIRCUT-Client
//
//  Created by Takuma Kawamura on 2019/07/15.
//  Copyright © 2019 NITMakers. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var bmiLevelIntArray: [Int]?
    var faceImageArray: [NSImage]?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        UserDefaults.standard.set(String("10.10.10.11"), forKey: "JetsonIPAddress")
        UserDefaults.standard.set(String("colorful"), forKey: "ChartColorTemplate")
        UserDefaults.standard.set(Int(6), forKey: "MUJIDivision")
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
}

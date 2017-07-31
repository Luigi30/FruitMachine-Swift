//
//  AppDelegate.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 7/19/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    let AppleScreenNotifications = Notification.Name("com.luigithirty.appleScreenNotifications")

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    @IBAction func view_scale_1x(_ sender: Any) {
        NotificationCenter.default.post(Notification(name: AppleScreenNotifications, object: "scaleFactor", userInfo: ["scaleFactor": 1]))
    }
    
    @IBAction func view_scale_2x(_ sender: Any) {
        NotificationCenter.default.post(Notification(name: AppleScreenNotifications, object: "scaleFactor", userInfo: ["scaleFactor": 2]))
    }
    
    func applicationShouldTerminateAfterLastWindowClosed (_ theApplication: NSApplication) -> Bool {
        return true
    }
    
}


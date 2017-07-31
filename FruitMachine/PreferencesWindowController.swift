//
//  PreferencesWindow.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 7/31/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

class PreferencesWindowController: NSWindowController {
    @IBOutlet weak var path_ROMMonitor: NSTextField!
    @IBOutlet weak var path_ROMCharacter: NSTextField!
    @IBOutlet weak var path_ROMBasic: NSTextField!
    
    let defaults = UserDefaults.standard
    
    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        let monitorPath = defaults.string(forKey: "path_ROMMonitor")
        let characterPath = defaults.string(forKey: "path_ROMCharacter")
        let basicPath = defaults.string(forKey: "path_ROMBasic")
        
        if (monitorPath != nil) {
            path_ROMMonitor.stringValue = monitorPath!
        }
        
        if (characterPath != nil) {
            path_ROMCharacter.stringValue = characterPath!
        }
        
        if (basicPath != nil) {
            path_ROMBasic.stringValue = basicPath!
        }
    }
    
    override var windowNibName : NSNib.Name? {
        return NSNib.Name(rawValue: "PreferencesWindow")
    }
    
}

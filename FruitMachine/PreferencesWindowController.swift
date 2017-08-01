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
    
    func windowWillClose(_ notification: Notification) {
        defaults.set(path_ROMMonitor.stringValue, forKey: "path_ROMMonitor")
        defaults.set(path_ROMCharacter.stringValue, forKey: "path_ROMCharacter")
        defaults.set(path_ROMBasic.stringValue, forKey: "path_ROMBasic")
        
        defaults.synchronize()
    }
    
    override var windowNibName : NSNib.Name? {
        return NSNib.Name(rawValue: "PreferencesWindow")
    }
    
    @IBAction func btn_click_Monitor(_ sender: NSButton) {
        let picker = NSOpenPanel()
        
        picker.title = "Select your Monitor ROM (apple1.rom)"
        picker.showsHiddenFiles = false
        picker.canChooseFiles = true
        picker.canChooseDirectories = false
        picker.allowsMultipleSelection = false
        picker.allowedFileTypes = ["rom"]
        
        if(picker.runModal() == .OK) {
            path_ROMMonitor.stringValue = picker.url!.path
        }
    }
    
    @IBAction func btn_click_Character(_ sender: NSButton) {
        let picker = NSOpenPanel()
        
        picker.title = "Select your Monitor ROM (apple1.vid)"
        picker.showsHiddenFiles = false
        picker.canChooseFiles = true
        picker.canChooseDirectories = false
        picker.allowsMultipleSelection = false
        picker.allowedFileTypes = ["vid"]
        
        if(picker.runModal() == .OK) {
            path_ROMCharacter.stringValue = picker.url!.path
        }
    }
    
    @IBAction func btn_click_BASIC(_ sender: NSButton) {
        let picker = NSOpenPanel()
        
        picker.title = "Select your Monitor ROM (basic.bin)"
        picker.showsHiddenFiles = false
        picker.canChooseFiles = true
        picker.canChooseDirectories = false
        picker.allowsMultipleSelection = false
        picker.allowedFileTypes = ["bin"]
        
        if(picker.runModal() == .OK) {
            path_ROMBasic.stringValue = picker.url!.path
        }
    }
    
    
}

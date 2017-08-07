//
//  PreferencesWindow.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 7/31/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

class PreferencesWindowController: NSWindowController {
    /* Apple I ROM paths */
    @IBOutlet weak var path_ROMMonitor: NSTextField!
    @IBOutlet weak var path_ROMCharacter: NSTextField!
    @IBOutlet weak var path_ROMBasic: NSTextField!
    
    /* Apple II ROM paths */
    
    /* Apple II Peripherals */
    @IBOutlet weak var a2_Peripherals_Slot0: NSPopUpButton!
    @IBOutlet weak var a2_Peripherals_Slot6: NSPopUpButton!
    
    let defaults = UserDefaults.standard
    
    override func windowDidLoad() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowWillClose),
            name: NSWindow.willCloseNotification,
            object: nil)
        
        setupPreferences()
        super.windowDidLoad()
    }
    
    func setupDefaultsIfRequired() {
//        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
//        UserDefaults.standard.synchronize()
        
        var slot0 = defaults.string(forKey: "a2_Peripherals_Slot0")
        var slot6 = defaults.string(forKey: "a2_Peripherals_Slot6")
        
        if(slot0 == nil) { slot0 = "Language Card (16K)" }
        if(slot6 == nil) { slot6 = "Disk II" }
        
        defaults.set(slot0, forKey: "a2_Peripherals_Slot0")
        defaults.set(slot6, forKey: "a2_Peripherals_Slot6")
    }
    
    func setupPreferences() {
        setupA1RomPaths()
        setupA2Peripherals()
    }
    
    func setupA1RomPaths() {
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
    
    func setupA2Peripherals() {
        let slot0 = defaults.string(forKey: "a2_Peripherals_Slot0")
        if(slot0 != nil) {
            a2_Peripherals_Slot6.selectItem(withTitle: slot0!)
        }
        
        let slot6 = defaults.string(forKey: "a2_Peripherals_Slot6")
        if(slot6 != nil) {
            a2_Peripherals_Slot6.selectItem(withTitle: slot6!)
        }
    }
    
    @objc func windowWillClose(_ notification: Notification) {
        defaults.set(path_ROMMonitor.stringValue, forKey: "path_ROMMonitor")
        defaults.set(path_ROMCharacter.stringValue, forKey: "path_ROMCharacter")
        defaults.set(path_ROMBasic.stringValue, forKey: "path_ROMBasic")
        
        defaults.set(a2_Peripherals_Slot0.selectedItem?.title, forKey: "a2_Peripherals_Slot0")
        defaults.set(a2_Peripherals_Slot6.selectedItem?.title, forKey: "a2_Peripherals_Slot6")
        
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

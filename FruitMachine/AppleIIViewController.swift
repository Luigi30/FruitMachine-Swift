//
//  AppleIIViewController.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 8/1/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

class EmulationNotifications {
    static let StartEmulation = Notification.Name("StartEmulation")
    static let StopEmulation = Notification.Name("StopEmulation")
}

class AppleIIViewController: NSViewController {    
    @IBOutlet weak var lbl_Drive1: NSTextField!
    @IBOutlet weak var lbl_Drive2: NSTextField!
    
    var debuggerWindowController: DebuggerWindowController!
    var preferencesWindowController: PreferencesWindowController!
    
    var isPaused = false
    var frameTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        preferencesWindowController = PreferencesWindowController()
        setModel()
        
        self.view.addSubview(EmulatedSystemInstance!.emulatorView)
        
        preferencesWindowController.setupDefaultsIfRequired()
        setupDriveNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(self.stopFrameTimer), name: EmulationNotifications.StopEmulation, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.startFrameTimer), name: EmulationNotifications.StartEmulation, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.breakpointHit), name: CPUNotifications.BreakpointHit, object: nil)
        startFrameTimer()
    }
    
    func setModel() {
        let model = UserDefaults.standard.string(forKey: "a2_Model")
        if (model == "Apple ][ (Original") {
            EmulatedSystemInstance = AppleII.sharedInstance
        } else if(model == "Apple ][+") {
            EmulatedSystemInstance = AppleIIPlus.sharedInstance
        } else {
            /* ??? */
            EmulatedSystemInstance = AppleII.sharedInstance
        }
    }
    
    @objc func breakpointHit() {
        stopFrameTimer()
        showDebugger(self)
    }
    
    @objc func runEmulation() {
        EmulatedSystemInstance!.runFrame()
        if(!CPU.sharedInstance.isRunning) {
            self.frameTimer?.invalidate()
        }
    }
    
    @objc func stopFrameTimer() {
        self.frameTimer?.invalidate()
    }
    
    @objc func startFrameTimer() {
        self.frameTimer = Timer.scheduledTimer(timeInterval: 1.0/60.0,
                                               target: self,
                                               selector: #selector(runEmulation),
                                               userInfo: nil,
                                               repeats: true)
    }
    
    @IBAction func showDebugger(_ sender: Any) {
        stopFrameTimer()
        let debuggerStoryboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Debugger"), bundle: nil)
        debuggerWindowController = debuggerStoryboard.instantiateInitialController() as! DebuggerWindowController
        debuggerWindowController.showWindow(self)
    }
    
    @IBAction func showPreferences(_ sender: Any) {
        stopFrameTimer()
        preferencesWindowController.loadWindow()
        preferencesWindowController.showWindow(self)
        preferencesWindowController.setupPreferences()
    }
    
    @IBAction func doReset(_ sender: Any) {
        EmulatedSystemInstance!.doReset()
    }
    
    @IBAction func doColdReset(_ sender: Any) {
        setModel()
        EmulatedSystemInstance!.setupPeripherals()
        EmulatedSystemInstance!.doColdReset()
    }
    
    @IBAction func insertDiskIntoDrive1(_ sender: Any) {
        let picker = NSOpenPanel()
        
        picker.title = "Select a 5.25\" disk image"
        picker.showsHiddenFiles = false
        picker.canChooseFiles = true
        picker.canChooseDirectories = false
        picker.allowsMultipleSelection = false
        picker.allowedFileTypes = ["do", "po"]
        
        if(picker.runModal() == .OK) {
            print("insertDiskIntoDrive1: \(EmulatedSystemInstance!.backplane[6]!)")
            EmulatedSystemInstance!.attachImageToDiskDrive(drive: EmulatedSystemInstance!.backplane[6]!, image: picker.url!.path)
        }
    }
    
    override func keyDown(with event: NSEvent) {
        let leftArrowKeyCode = 123
        let rightArrowKeyCode = 124
        
        let c = returnChar(theEvent: event)
        
        if(event.keyCode == leftArrowKeyCode) {
            EmulatedSystemInstance!.keyboardController.KEYBOARD = UInt8((0x08 | 0x80) & 0x000000FF)
        } else if(event.keyCode == rightArrowKeyCode) {
            EmulatedSystemInstance!.keyboardController.KEYBOARD = UInt8((0x15 | 0x80) & 0x000000FF)
        }
        
        guard let ascii32 = c?.asciiValue else {
            return
        }
        
        //Set the keyboard input register accordingly. Set b7 so the OS knows there's a keypress waiting
        EmulatedSystemInstance!.keyboardController.KEYBOARD = UInt8((ascii32 | 0x80) & 0x000000FF)
    }
    
    private func returnChar(theEvent: NSEvent) -> Character?{
        let s: String = theEvent.characters!
        for char in s{
            return char
        }
        return nil
    }
    
    func setupDriveNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.drive1MotorOn), name: DiskII.N_Drive1MotorOn, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.drive2MotorOn), name: DiskII.N_Drive2MotorOn, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.drive1MotorOff), name: DiskII.N_Drive1MotorOff, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.drive2MotorOff), name: DiskII.N_Drive2MotorOff, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.drive1TrackChanged), name: DiskII.N_Drive1TrackChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.drive2TrackChanged), name: DiskII.N_Drive2TrackChanged, object: nil)
        
    }
    
    /* drive lights */
    @objc func drive1TrackChanged(notification: NSNotification) {
        let num = notification.object as? (Int, Int)
        lbl_Drive1.stringValue = "D1 T\(num!.0) S\(num!.1)"
    }
    @objc func drive2TrackChanged(notification: NSNotification) {
        let num = notification.object as? (Int, Int)
        lbl_Drive2.stringValue = "D1 T\(num!.0) S\(num!.1)"
    }
    
    @objc func drive1MotorOff(notification: NSNotification) {
        lbl_Drive1.textColor = NSColor.textColor
    }
    
    @objc func drive2MotorOff(notification: NSNotification) {
        lbl_Drive2.textColor = NSColor.textColor
    }
    
    @objc func drive1MotorOn(notification: NSNotification) {
        lbl_Drive1.textColor = NSColor.red
    }
    
    @objc func drive2MotorOn(notification: NSNotification) {
        lbl_Drive2.textColor = NSColor.red
    }
    
}

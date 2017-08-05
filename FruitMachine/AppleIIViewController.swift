//
//  AppleIIViewController.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 8/1/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

class AppleIIViewController: NSViewController {
    
    @IBOutlet weak var lbl_Drive1: NSTextField!
    @IBOutlet weak var lbl_Drive2: NSTextField!
    
    let computer = AppleII.sharedInstance
    var debuggerWindowController: DebuggerWindowController!
    var preferencesWindowController: PreferencesWindowController!
    
    var isPaused = false
    var frameTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        preferencesWindowController = PreferencesWindowController()
        
        self.view.addSubview(computer.emulatorView)
        
        setupDriveNotifications()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.debuggerBreak), name: DebuggerNotifications.Break, object: nil)
        
        self.frameTimer = Timer.scheduledTimer(timeInterval: 1.0/60.0,
                                               target: self,
                                               selector: #selector(runEmulation),
                                               userInfo: nil,
                                               repeats: true)
    }
    
    @objc func runEmulation() {
        computer.runFrame()
        if(!CPU.sharedInstance.isRunning) {
            self.frameTimer?.invalidate()
        }
    }
    
    @objc func debuggerBreak() {
        frameTimer?.invalidate()
        CPU.sharedInstance.isRunning = false
    }
    
    @IBAction func showDebugger(_ sender: Any) {        
        let debuggerStoryboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Debugger"), bundle: nil)
        debuggerWindowController = debuggerStoryboard.instantiateInitialController() as! DebuggerWindowController
        debuggerWindowController.showWindow(self)
    }
    
    @IBAction func showPreferences(_ sender: Any) {
        preferencesWindowController.loadWindow()
    }
    
    @IBAction func doReset(_ sender: Any) {
        computer.doReset()
    }
    
    override func keyDown(with event: NSEvent) {
        let leftArrowKeyCode = 123
        let rightArrowKeyCode = 124
        
        let c = returnChar(theEvent: event)
        
        if(event.keyCode == leftArrowKeyCode) {
            computer.keyboardController.KEYBOARD = UInt8((0x08 | 0x80) & 0x000000FF)
        } else if(event.keyCode == rightArrowKeyCode) {
            computer.keyboardController.KEYBOARD = UInt8((0x15 | 0x80) & 0x000000FF)
        }
        
        guard let ascii32 = c?.asciiValue else {
            return
        }
        
        //Set the keyboard input register accordingly. Set b7 so the OS knows there's a keypress waiting
        computer.keyboardController.KEYBOARD = UInt8((ascii32 | 0x80) & 0x000000FF)
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
        let num = notification.object as? Int
        lbl_Drive1.stringValue = "D1 \(num!)"
    }
    @objc func drive2TrackChanged(notification: NSNotification) {
        let num = notification.object as? Int
        lbl_Drive2.stringValue = "D2 \(num!)"
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

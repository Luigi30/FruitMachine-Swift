//
//  AppleIIViewController.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 8/1/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

class AppleIIViewController: NSViewController {
    
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
    
}

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
        
        self.frameTimer = Timer.scheduledTimer(timeInterval: 1/60,
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
    
}
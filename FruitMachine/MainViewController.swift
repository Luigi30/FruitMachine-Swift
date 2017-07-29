//
//  MainViewController.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 7/26/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa
import CoreGraphics

class MainViewController: NSViewController {
    
    let computer = AppleI.sharedInstance
    var debuggerWindowController: DebuggerWindowController!
    
    var isPaused = false
    var frameTimer: Timer?
    
    override func viewDidLoad() {        
        super.viewDidLoad()

        let debuggerStoryboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Debugger"), bundle: nil)
        debuggerWindowController = debuggerStoryboard.instantiateInitialController() as! DebuggerWindowController
        debuggerWindowController.showWindow(self)
        
        // Do view setup here.
        self.view.addSubview(computer.emulatorView)
        computer.emulatorView.display()
        
        self.frameTimer = Timer.scheduledTimer(timeInterval: 1/60, target: self, selector: #selector(runEmulation), userInfo: nil, repeats: true)
        //runEmulation()
    }
    
    @objc func runEmulation() {
        AppleI.sharedInstance.runFrame()
        computer.emulatorView.setNeedsDisplay(computer.emulatorView.frame)
        computer.emulatorView.layer!.setNeedsDisplay(computer.emulatorView.layer!.frame)
        computer.emulatorView.display()
    }
    
    override func keyDown(with event: NSEvent) {
        let character = event.characters?.first
        
        computer.pia["keyboard"]?.data = 0x41
        computer.pia["keyboard"]?.control |= 0x80
    }

}

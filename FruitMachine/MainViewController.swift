//
//  MainViewController.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 7/26/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa
import CoreGraphics
import OpenGL
import GLKit

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
        
        //computer.emuGLView.doSetup()
        //self.view.addSubview(computer.emuGLView)
        
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
    
    override func keyDown(with event: NSEvent) {
        let c = returnChar(theEvent: event)
        
        guard let ascii32 = c?.asciiValue else {
            return
        }

        computer.pia["keyboard"]?.data = UInt8(ascii32 & 0x000000FF)
        computer.pia["keyboard"]?.control |= 0x80
    }
    
    private func returnChar(theEvent: NSEvent) -> Character?{
        let s: String = theEvent.characters!
        for char in s{
            return char
        }
        return nil
    }

}

extension Character {
    var asciiValue: UInt32? {
        return String(self).unicodeScalars.filter{$0.isASCII}.first?.value
    }
}

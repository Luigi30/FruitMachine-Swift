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
    
    override func viewDidLoad() {        
        super.viewDidLoad()

        let debuggerStoryboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Debugger"), bundle: nil)
        debuggerWindowController = debuggerStoryboard.instantiateInitialController() as! DebuggerWindowController
        debuggerWindowController.showWindow(self)
        
        // Do view setup here.
        self.view.addSubview(computer.emulatorView)
        computer.emulatorView.display()
        
        computer.runFrame()
    }

}

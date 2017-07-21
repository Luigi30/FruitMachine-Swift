//
//  ViewController.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 7/19/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    let CPU = CPUState.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()

        CPU.memoryInterface.memory[0] = 0xAD
        
        CPU.memoryInterface.memory[1] = 0x34
        CPU.memoryInterface.memory[2] = 0x12
        
        CPU.memoryInterface.memory[0x1234] = 0xAA
        
        do {
            try CPU.executeNextInstruction()
            try CPU.executeNextInstruction()
        } catch CPUExceptions.invalidInstruction {
            print("*** 6502 Exception: Invalid instruction 0xXX at 0xXXXX")
        } catch {
            print(error)
        }
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}


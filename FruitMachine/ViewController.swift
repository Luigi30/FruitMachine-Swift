//
//  ViewController.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 7/19/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    @IBOutlet weak var text_CPU_A: NSTextField!
    @IBOutlet weak var text_CPU_X: NSTextField!
    @IBOutlet weak var text_CPU_Y: NSTextField!
    @IBOutlet weak var text_CPU_IP: NSTextField!
    @IBOutlet weak var text_CPU_SR: NSTextField!
    
    let CPU = CPUState.sharedInstance
    
    func updateCPUStatusFields() {
        text_CPU_A.stringValue = String(format:"%02X", CPU.accumulator)
        text_CPU_X.stringValue = String(format:"%02X", CPU.index_x)
        text_CPU_Y.stringValue = String(format:"%02X", CPU.index_y)
        text_CPU_IP.stringValue = String(format:"%04X", CPU.instruction_register)
        text_CPU_SR.stringValue = String(format:"%02X", CPU.instruction_register)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        CPU.memoryInterface.loadBinary(path: "/Users/luigi/6502/test.bin")
        updateCPUStatusFields()
        
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    func cpuStep() {
        do {
            try CPU.executeNextInstruction()
            updateCPUStatusFields()
        } catch CPUExceptions.invalidInstruction {
            print("*** 6502 Exception: Invalid instruction 0xXX at 0xXXXX")
        } catch {
            print(error)
        }
    }
    
    @IBAction func btn_CPUStep(_ sender: Any) {
        cpuStep()
    }

}


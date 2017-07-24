//
//  ViewController.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 7/19/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

class DebuggerViewController: NSViewController {
    @IBOutlet weak var text_CPU_A: NSTextField!
    @IBOutlet weak var text_CPU_X: NSTextField!
    @IBOutlet weak var text_CPU_Y: NSTextField!
    @IBOutlet weak var text_CPU_IP: NSTextField!
    @IBOutlet weak var text_CPU_SR: NSTextField!
    @IBOutlet weak var text_CPU_Flags: NSTextField!
    
    @IBOutlet weak var debuggerTableView: NSTableView!
    
    var cpuInstance = CPU.sharedInstance
    var isRunning = false
    
    var disassembly: [Disassembly] = [Disassembly]()
    
    func highlightCurrentInstruction() -> Bool {
        for (index, instruction) in disassembly.enumerated() {
            if(instruction.address == cpuInstance.program_counter) {
                debuggerTableView.selectRowIndexes(NSIndexSet(index: index) as IndexSet, byExtendingSelection: false)
                debuggerTableView.scrollRowToVisible(index+10)
                debuggerTableView.scrollRowToVisible(index-5)
                return true //instruction found
            }
        }
        return false //instruction not found
    }
    
    func updateCPUStatusFields() {
        text_CPU_A.stringValue = String(format:"%02X", cpuInstance.accumulator)
        text_CPU_X.stringValue = String(format:"%02X", cpuInstance.index_x)
        text_CPU_Y.stringValue = String(format:"%02X", cpuInstance.index_y)
        text_CPU_IP.stringValue = String(format:"%04X", cpuInstance.program_counter)
        text_CPU_SR.stringValue = String(format:"%02X", cpuInstance.stack_pointer)
        text_CPU_Flags.stringValue = String(cpuInstance.status_register.asString())
        
        if(!highlightCurrentInstruction()) {
            disassembly = cpuInstance.disassemble(fromAddress: cpuInstance.program_counter, length: 256)
            highlightCurrentInstruction()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        debuggerTableView.delegate = self
        debuggerTableView.dataSource = self

        cpuInstance.memoryInterface.loadBinary(path: "/Users/luigi/6502/test.bin")
        cpuInstance.performReset()
        cpuInstance.program_counter = 0x400 //entry point for the test program
        updateCPUStatusFields()
        disassembly = cpuInstance.disassemble(fromAddress: cpuInstance.program_counter, length: 10000)
        debuggerTableView.reloadData()
        
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    func cpuStep() {
        do {
            try cpuInstance.executeNextInstruction()
        } catch CPUExceptions.invalidInstruction {
            print("*** 6502 Exception: Invalid instruction 0xXX at 0xXXXX")
        } catch {
            print(error)
        }
    }
    
    func cpuRun() {
        isRunning = true
        let queue = DispatchQueue(label: "com.luigithirty.m6502.instructions")
        let main  = DispatchQueue.main
        
        queue.async {
            while(self.isRunning == true)
            {
                queue.asyncAfter(deadline: .now() + .seconds(1), execute: {
                    self.cpuStep()
                    main.sync {
                        self.updateCPUStatusFields()
                    }
                })
            }
        }
    }
    
    @IBAction func btn_CPUStep(_ sender: Any) {
        cpuStep()
        updateCPUStatusFields()
    }

    @IBAction func btn_Break(_ sender: Any) {
        isRunning = false
        _ = 0
    }
    
    @IBAction func btn_CPURun(_ sender: Any) {
        cpuRun()
    }
    
    
}

extension DebuggerViewController: NSTableViewDelegate {
   
    fileprivate enum CellIdentifiers {
        static let AddressCell = "AddressCellID"
        static let DataCell = "DataCellID"
        static let BytesCell = "BytesCellID"
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var cellText: String = ""
        var cellIdentifier: String = ""
        let operation = disassembly[row]
        
        if(tableColumn == tableView.tableColumns[0]) {
            cellText = String(format: "%04X", operation.address)
            cellIdentifier = CellIdentifiers.AddressCell
        }
        
        if(tableColumn == tableView.tableColumns[1]) {
            if(operation.instruction == nil) {
                cellText = "ILLEGAL"
            } else {
                switch(operation.instruction!.addressingMode) {
                case .accumulator:
                    cellText = String(format: "%@ A", operation.instruction!.mnemonic)
                case .immediate:
                    cellText = String(format: "%@ #$%02X", operation.instruction!.mnemonic, operation.data[1])
                case .implied:
                    cellText = String(format: "%@", operation.instruction!.mnemonic)
                case .relative:
                    var destination: UInt16 = operation.address
                    if((operation.data[1] & 0x80) == 0x80) {
                        destination = destination + 1 - UInt16(~operation.data[1])
                    } else {
                        destination = destination + UInt16(operation.data[1])
                    }
                    cellText = String(format: "%@ #$%04X", operation.instruction!.mnemonic, destination)
                case .absolute:
                    cellText = String(format: "%@ $%02X%02X", operation.instruction!.mnemonic, operation.data[2], operation.data[1])
                case .zeropage:
                    cellText = String(format: "%@ $%02X", operation.instruction!.mnemonic, operation.data[1])
                case .indirect:
                    cellText = String(format: "%@ ($%02X%02X)", operation.instruction!.mnemonic, operation.data[2], operation.data[1])
                case .absolute_indexed_x:
                    cellText = String(format: "%@ $%02X%02X,X", operation.instruction!.mnemonic, operation.data[2], operation.data[1])
                case .absolute_indexed_y:
                    cellText = String(format: "%@ $%02X%02X,Y", operation.instruction!.mnemonic, operation.data[2], operation.data[1])
                case .zeropage_indexed_x:
                    cellText = String(format: "%@ $%02X,X", operation.instruction!.mnemonic, operation.data[1])
                case .zeropage_indexed_y:
                    cellText = String(format: "%@ $%02X,Y", operation.instruction!.mnemonic, operation.data[1])
                case .indexed_indirect:
                    cellText = String(format: "%@ ($%02X,X)", operation.instruction!.mnemonic, operation.data[1])
                case .indirect_indexed:
                    cellText = String(format: "%@ ($%02X),Y", operation.instruction!.mnemonic, operation.data[1])
                }
            }
            cellIdentifier = CellIdentifiers.DataCell
        }
        
        if(tableColumn == tableView.tableColumns[2]) {
            cellText = ""
            for byte in operation.data {
                cellText += String(format: "%02X ", byte)
            }
            
            cellIdentifier = CellIdentifiers.BytesCell
        }
        
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = cellText
            return cell
        }
        
        return nil
    }

}

extension DebuggerViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return disassembly.count
    }
    
    func getItem(atIndex: Int) -> Disassembly {
        return disassembly[atIndex]
    }
}

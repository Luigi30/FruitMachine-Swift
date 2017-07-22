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
    
    @IBOutlet weak var debuggerTableView: NSTableView!
    
    let CPU = CPUState.sharedInstance
    var disassembly: [Disassembly] = [Disassembly]()
    
    func updateCPUStatusFields() {
        text_CPU_A.stringValue = String(format:"%02X", CPU.accumulator)
        text_CPU_X.stringValue = String(format:"%02X", CPU.index_x)
        text_CPU_Y.stringValue = String(format:"%02X", CPU.index_y)
        text_CPU_IP.stringValue = String(format:"%04X", CPU.program_counter)
        text_CPU_SR.stringValue = String(format:"%02X", CPU.stack_pointer)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        debuggerTableView.delegate = self
        debuggerTableView.dataSource = self

        CPU.memoryInterface.loadBinary(path: "/Users/luigi/6502/test.bin")
        updateCPUStatusFields()
        disassembly = CPU.disassemble(fromAddress: 0x0000, length: 16)
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

extension DebuggerViewController: NSTableViewDelegate {
   
    fileprivate enum CellIdentifiers {
        static let AddressCell = "AddressCellID"
        static let DataCell = "DataCellID"
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
                    cellText = String(format: "%@ #%02X", operation.instruction!.mnemonic, operation.data[0])
                case .implied:
                    cellText = String(format: "%@", operation.instruction!.mnemonic)
                case .relative:
                    cellText = String(format: "%@ #%04X", operation.instruction!.mnemonic, UInt16(operation.data[0]) + operation.address)
                case .absolute:
                    cellText = String(format: "%@ #%02X%02X", operation.instruction!.mnemonic, operation.data[1], operation.data[0])
                case .zeropage:
                    cellText = String(format: "%@ $%02X", operation.instruction!.mnemonic, operation.data[0])
                case .indirect:
                    cellText = String(format: "%@ ($%02X%02X)", operation.instruction!.mnemonic, operation.data[1], operation.data[0])
                case .absolute_indexed_x:
                    cellText = String(format: "%@ #%02X%02X,X", operation.instruction!.mnemonic, operation.data[1], operation.data[0])
                case .absolute_indexed_y:
                    cellText = String(format: "%@ #%02X%02X,Y", operation.instruction!.mnemonic, operation.data[1], operation.data[0])
                case .zeropage_indexed_x:
                    cellText = String(format: "%@ $%02X,X", operation.instruction!.mnemonic, operation.data[0])
                case .zeropage_indexed_y:
                    cellText = String(format: "%@ $%02X,Y", operation.instruction!.mnemonic, operation.data[0])
                case .indexed_indirect:
                    cellText = String(format: "%@ ($%02X,X)", operation.instruction!.mnemonic, operation.data[0])
                case .indirect_indexed:
                    cellText = String(format: "%@ ($%02X),Y", operation.instruction!.mnemonic, operation.data[0])
                }
            }
            cellIdentifier = CellIdentifiers.DataCell
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

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
    
    @IBOutlet weak var text_debugger_output: NSTextView!
    @IBOutlet weak var text_debugger_input: NSTextField!
    
    @IBOutlet weak var debuggerTableView: NSTableView!
    
    var cpuInstance = CPU.sharedInstance
    var isRunning = false
    
    var disassembly: [Disassembly] = [Disassembly]()
    
    @discardableResult func highlightCurrentInstruction() -> Bool {
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
        
        disassembly = cpuInstance.disassemble(fromAddress: CPU.sharedInstance.program_counter, length: 256)
        debuggerTableView.reloadData()
        highlightCurrentInstruction()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        debuggerTableView.delegate = self
        debuggerTableView.dataSource = self

        updateCPUStatusFields()
        disassembly = cpuInstance.disassemble(fromAddress: CPU.sharedInstance.program_counter, length: 256)
        debuggerTableView.reloadData()
        
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func debugRun() {
        isRunning = true
        
        cpuInstance.cycles = 0
        cpuInstance.cyclesInBatch = 10000
        
        while(!cpuInstance.outOfCycles() && isRunning) {
            cpuInstance.cpuStep()
            
            if (cpuInstance.breakpoints.contains(cpuInstance.program_counter)) {
                isRunning = false
                updateCPUStatusFields()
                debugConsolePrint(str: "Breakpoint reached at $\(cpuInstance.program_counter.asHexString())", newline: true)
            }
        }
        
    }
    
    func queueCPUStep(queue: DispatchQueue) {
        queue.async {
            self.cpuInstance.cpuStep()
        }
    }
    
    @IBAction func btn_CPUStep(_ sender: Any) {
        cpuInstance.cpuStep()
        updateCPUStatusFields()
    }

    @IBAction func btn_Break(_ sender: Any) {
        isRunning = false
        _ = 0
    }
    
    @IBAction func btn_CPURun(_ sender: Any) {
        debugRun()
    }

    @IBAction func btn_CPU_Restart(_ sender: Any) {
        cpuInstance.performReset()
        cpuInstance.program_counter = 0x400
        debugConsolePrint(str: "CPU restarted from \(cpuInstance.program_counter)", newline: true)
    }
    
    
    @IBAction func debuggerInput_submit(_ sender: NSTextField) {
        interpretCommand(command: sender.stringValue)
        sender.stringValue = ""
    }
    
    func debugConsolePrint(str: String, newline: Bool) {
        text_debugger_output.appendText(line: str)
        if(newline) {
            text_debugger_output.appendText(line:"\r\n")
        }
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
        
        if(row >= disassembly.count) {
            return nil //no cell
        }
        
        let operation = disassembly[row]
        
        if(tableColumn == tableView.tableColumns[0]) {
            cellText = operation.getAddressString()
            cellIdentifier = CellIdentifiers.AddressCell
        }
        
        if(tableColumn == tableView.tableColumns[1]) {
            if(operation.instruction == nil) {
                cellText = "ILLEGAL"
            } else {
                cellText = operation.getInstructionString()
            }
            cellIdentifier = CellIdentifiers.DataCell
        }
        
        if(tableColumn == tableView.tableColumns[2]) {
            cellText = operation.getDataString()            
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

extension NSTextView {
    func appendText(line: String) {
        let attrDict = [NSAttributedStringKey.font: NSFont.userFixedPitchFont(ofSize: 11)]
        let astring = NSAttributedString(string: "\(line)", attributes: attrDict)
        self.textStorage?.append(astring)
        let loc = self.string.lengthOfBytes(using: String.Encoding.utf8)
        
        let range = NSRange(location: loc, length: 0)
        self.scrollRangeToVisible(range)
    }
}

func xlog(logView:NSTextView?, line:String) {
    if let view = logView {
        view.appendText(line: line)
    }
}

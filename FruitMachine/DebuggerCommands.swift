//
//  DebuggerCommands.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 7/24/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

extension DebuggerViewController {
    func interpretCommand(command: String) {
        debugConsolePrint(str: "> \(command)", newline: true)
        
        let commandSplit = command.components(separatedBy: " ")
        var parameters: [String] = commandSplit
        parameters.remove(at: 0)
        
        if(commandSplit[0] == "bplist")
        {
            debugConsolePrint(str: DebuggerCommands.bplist(state: cpuInstance, parameters: parameters), newline: true)
        }
        else if(commandSplit[0] == "bpdel")
        {
            debugConsolePrint(str: DebuggerCommands.bpdel(state: cpuInstance, parameters: parameters), newline: true)
        }
        else if(commandSplit[0] == "bpadd")
        {
            debugConsolePrint(str: DebuggerCommands.bpadd(state: cpuInstance, parameters: parameters), newline: true)
        }
        else
        {
            debugConsolePrint(str: "Unrecognized command", newline: true)
        }
        text_debugger_output.scrollToEndOfDocument(self)
    }
}

class DebuggerCommands: NSObject {
    static func bplist(state: CPU, parameters: [String]) -> String {
        var output = ""
        for (index, bp) in state.breakpoints.enumerated() {
            output += "Breakpoint \(index): $\(bp.asHexString())\r\n"
        }
        
        return output
    }
    
    static func bpadd(state: CPU, parameters: [String]) -> String {
        var output = ""
        let val = UInt16(parameters[0])
        
        if(val != nil) {
            state.breakpoints.append(val!)
            output += "Breakpoint added at $\(val!.asHexString())."
        }
        else {
            output += "Usage: bpadd <address>"
        }
        
        return output
    }
    
    static func bpdel(state: CPU, parameters: [String]) -> String {
        var output = ""
        let val = Int(parameters[0])
        
        if(val != nil)
        {
            if (val! >= 0 && val! < state.breakpoints.count) {
                state.breakpoints.remove(at: val!)
                output += "Breakpoint \(val!) deleted."
            }
            else
            {
                output += "Breakpoint \(val!) does not exist."
            }
        }
        else
        {
            output += "Usage: bpdel <breakpoint-number>. Use bplist to find breakpoint numbers."
        }
        
        return output
    }
}
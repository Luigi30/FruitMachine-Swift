//
//  DebugConsole.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 7/24/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

class DebugConsole: NSObject {
    func interpretCommand(command: String) {
        let commandSplit = command.split(separator: " ")
        if(commandSplit[0] == "bplist") {
            
        }
        
    }
}

class DebugCommands: NSObject {
    static func bplist() -> String {
        
    }
}

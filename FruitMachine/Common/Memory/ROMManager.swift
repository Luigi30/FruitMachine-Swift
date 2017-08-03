//
//  HasROM.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 8/2/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Foundation

protocol HasROM {
    var romManager: ROMManager { get }
}

protocol ROMDelegate {
    var ROM: [UInt8] { get }
    init(path: String, atAddress: UInt16, size: Int)
}

class ROMManager: ROMDelegate {
    var ROM: [UInt8]
    
    required init(path: String, atAddress: UInt16, size: Int) {
        ROM = [UInt8](repeating: 0xCC, count: size)
        
        do {
            let fileContent: NSData = try NSData(contentsOfFile: path)
            fileContent.getBytes(&ROM, range: NSRange(location: Int(atAddress), length: size))
        } catch {
            print(error)
        }
    }
}

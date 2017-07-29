//
//  PIA.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 7/28/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

class PIA: NSObject {
    enum PIAMode {
        case DDR
        case Output
    }
    
    var data: UInt8
    var control: UInt8
    
    override init() {
        data = 0x00
        control = 0x00
    }
    
    func getMode() -> PIAMode {
        if((control & 0x04) == 0x04) {
            return .Output
        } else {
            return .DDR
        }
    }

}

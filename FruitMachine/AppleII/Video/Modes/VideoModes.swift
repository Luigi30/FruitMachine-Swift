//
//  VideoModes.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 8/2/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

extension AppleIIBase {
    
    static let PAGE1_BASE: Address = 0x400
    static let PAGE2_BASE: Address = 0x800
    
    typealias Softswitch = Bool
    
    struct VideoSoftswitches {
        var TEXT_MODE: Softswitch = false   // $C050/$C051
        var MIX_MODE: Softswitch = false    // $C052/$C053
        var PAGE_2: Softswitch = false      // $C054/$C055
        var HIRES_MODE: Softswitch = false  // $C056/$C057
        
        mutating func reset() {
            TEXT_MODE = true
            MIX_MODE = false
            PAGE_2 = false
            HIRES_MODE = false
        }
    }

    enum VideoMode {
        case Text
        case Lores
        case Hires
        case MixedLores
        case MixedHires
    }
    
    func getCurrentVideoMode(switches: VideoSoftswitches) -> VideoMode {
        if(switches.TEXT_MODE == true)
        {
            return .Text
        }
        else if(switches.MIX_MODE) {
            if(switches.HIRES_MODE == false) {
                return .MixedLores
            } else {
                return .MixedHires
            }
        }
        else if(switches.HIRES_MODE) {
            return .Hires
        } else {
            return .Lores
        }
    }
}

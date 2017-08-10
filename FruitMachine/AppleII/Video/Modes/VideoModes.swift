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
    
    struct LoresColors {
        static let Black        = BitmapPixelsLE555.RGB32toLE555(r: 0, g: 0, b: 0)
        static let Magenta      = BitmapPixelsLE555.RGB32toLE555(r: 227, g: 30, b: 96)
        static let DarkBlue     = BitmapPixelsLE555.RGB32toLE555(r: 96, g: 78, b: 189)
        static let Purple       = BitmapPixelsLE555.RGB32toLE555(r: 255, g: 68, b: 253)
        static let DarkGreen    = BitmapPixelsLE555.RGB32toLE555(r: 0, g: 163, b: 96)
        static let Gray1        = BitmapPixelsLE555.RGB32toLE555(r: 156, g: 156, b: 156)
        static let MediumBlue   = BitmapPixelsLE555.RGB32toLE555(r: 20, g: 207, b: 253)
        static let LightBlue    = BitmapPixelsLE555.RGB32toLE555(r: 208, g: 195, b: 255)
        static let Brown        = BitmapPixelsLE555.RGB32toLE555(r: 96, g: 114, b: 3)
        static let Orange       = BitmapPixelsLE555.RGB32toLE555(r: 255, g: 106, b: 60)
        static let Gray2        = BitmapPixelsLE555.RGB32toLE555(r: 156, g: 156, b: 156)
        static let Pink         = BitmapPixelsLE555.RGB32toLE555(r: 255, g: 160, b: 208)
        static let LightGreen   = BitmapPixelsLE555.RGB32toLE555(r: 20, g: 245, b: 60)
        static let Yellow       = BitmapPixelsLE555.RGB32toLE555(r: 208, g: 221, b: 141)
        static let Aquamarine   = BitmapPixelsLE555.RGB32toLE555(r: 114, g: 255, b: 208)
        static let White        = BitmapPixelsLE555.RGB32toLE555(r: 255, g: 255, b: 255)
        
        static func getColor(index: UInt8) -> BitmapPixelsLE555.PixelData {
            switch index {
            case 0: return AppleII.LoresColors.Black
            case 1: return AppleII.LoresColors.Magenta
            case 2: return AppleII.LoresColors.DarkBlue
            case 3: return AppleII.LoresColors.Purple
            case 4: return AppleII.LoresColors.DarkGreen
            case 5: return AppleII.LoresColors.Gray1
            case 6: return AppleII.LoresColors.MediumBlue
            case 7: return AppleII.LoresColors.LightBlue
            case 8: return AppleII.LoresColors.Brown
            case 9: return AppleII.LoresColors.Orange
            case 10: return AppleII.LoresColors.Gray2
            case 11: return AppleII.LoresColors.Pink
            case 12: return AppleII.LoresColors.LightGreen
            case 13: return AppleII.LoresColors.Yellow
            case 14: return AppleII.LoresColors.Aquamarine
            case 15: return AppleII.LoresColors.White
            default:
                print("tried to get color > 15")
                return AppleII.LoresColors.Black
            }

        }
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

//
//  Terminal.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 7/27/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

struct Cell {
    var x: Int
    var y: Int
}

class Terminal: NSObject {
    static let CELLS_WIDTH = 40
    static let CELLS_HEIGHT = 24
    
    var cursorPosition: Cell
    var characters: [UInt8]
    
    override init() {
        cursorPosition = Cell(x: 0, y: 0)
        characters = [UInt8](repeating: 0x40, count: Terminal.CELLS_WIDTH * Terminal.CELLS_HEIGHT)
    }
    
    func cellToIndex(cell: Cell) -> Int {
        return (cell.y * Terminal.CELLS_WIDTH) + (cell.x % Terminal.CELLS_WIDTH)
    }
    
    func putCharacter(charIndex: UInt8) {
        characters[cellToIndex(cell: cursorPosition)] = charIndex
        advanceCursor()
    }
    
    func advanceCursor() {
        cursorPosition.x += 1
        if(cursorPosition.x == Terminal.CELLS_WIDTH) {
            cursorPosition.x = 0
            cursorPosition.y += 1
            if(cursorPosition.y == Terminal.CELLS_HEIGHT) {
                cursorPosition.y = 0 //TODO: scrolling
            }
        }
    }
}

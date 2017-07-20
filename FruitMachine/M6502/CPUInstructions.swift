//
//  CPUInstructions.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 7/20/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

enum AddressingMode {
    case accumulator
    case immediate
    case implied
    case relative
    case absolute
    case zeropage
    case indirect
    case absolute_indexed_x
    case absolute_indexed_y
    case zeropage_indexed_x
    case zeropage_indexed_y
    case indexed_indirect
    case indirect_indexed
}

class CPUInstruction: NSObject {
    let mnemonic: String    //The mnemonic for this instruction.
    let cycles: Int         //How many cycles does this instruction take?
    let bytes: Int          //How many bytes long is this instruction?
    let addressingMode: AddressingMode //The addressing mode of this instruction.
    
    let action: (CPUState, AddressingMode) -> Void //A closure that describes this function's action.
    
    init(mnemonic: String, cycles: Int, bytes: Int, addressingMode: AddressingMode, action: @escaping (CPUState, AddressingMode) -> Void) {
        self.mnemonic = mnemonic
        self.cycles = cycles
        self.bytes = bytes
        self.addressingMode = addressingMode
        self.action = action
    }
}

let InstructionTable: [UInt8:CPUInstruction] = [
    0xA5: CPUInstruction.init(mnemonic: "LDA", cycles: 3, bytes: 2, addressingMode: .zeropage,              action: Opcodes.LDA),
    0xA9: CPUInstruction.init(mnemonic: "LDA", cycles: 2, bytes: 2, addressingMode: .immediate,             action: Opcodes.LDA),
    0xAD: CPUInstruction.init(mnemonic: "LDA", cycles: 4, bytes: 3, addressingMode: .absolute,              action: Opcodes.LDA),
    0xB5: CPUInstruction.init(mnemonic: "LDA", cycles: 4, bytes: 2, addressingMode: .zeropage_indexed_x,    action: Opcodes.LDA),
    0xB9: CPUInstruction.init(mnemonic: "LDA", cycles: 4, bytes: 3, addressingMode: .absolute_indexed_y,    action: Opcodes.LDA),
    0xBD: CPUInstruction.init(mnemonic: "LDA", cycles: 4, bytes: 3, addressingMode: .absolute_indexed_x,    action: Opcodes.LDA),
]

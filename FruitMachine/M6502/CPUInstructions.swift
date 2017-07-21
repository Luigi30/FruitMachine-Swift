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

//indexed_indirect = LDA ($00,X)
//indirect_indexed = LDA ($00),Y

let InstructionTable: [UInt8:CPUInstruction] = [
    
    //LD instructions
    0xA9: CPUInstruction.init(mnemonic: "LDA", cycles: 2, bytes: 2, addressingMode: .immediate,             action: Opcodes.LDA),
    0xA5: CPUInstruction.init(mnemonic: "LDA", cycles: 3, bytes: 2, addressingMode: .zeropage,              action: Opcodes.LDA),
    0xB5: CPUInstruction.init(mnemonic: "LDA", cycles: 4, bytes: 2, addressingMode: .zeropage_indexed_x,    action: Opcodes.LDA),
    0xAD: CPUInstruction.init(mnemonic: "LDA", cycles: 4, bytes: 3, addressingMode: .absolute,              action: Opcodes.LDA),
    0xBD: CPUInstruction.init(mnemonic: "LDA", cycles: 4, bytes: 3, addressingMode: .absolute_indexed_x,    action: Opcodes.LDA),
    0xB9: CPUInstruction.init(mnemonic: "LDA", cycles: 4, bytes: 3, addressingMode: .absolute_indexed_y,    action: Opcodes.LDA),
    0xA1: CPUInstruction.init(mnemonic: "LDA", cycles: 6, bytes: 2, addressingMode: .indexed_indirect,      action: Opcodes.LDA),
    0xB1: CPUInstruction.init(mnemonic: "LDA", cycles: 5, bytes: 2, addressingMode: .indirect_indexed,      action: Opcodes.LDA),
    
    0xA2: CPUInstruction.init(mnemonic: "LDX", cycles: 2, bytes: 2, addressingMode: .immediate,             action: Opcodes.LDX),
    0xA6: CPUInstruction.init(mnemonic: "LDX", cycles: 3, bytes: 2, addressingMode: .zeropage,              action: Opcodes.LDX),
    0xB6: CPUInstruction.init(mnemonic: "LDX", cycles: 4, bytes: 2, addressingMode: .zeropage_indexed_y,    action: Opcodes.LDX),
    0xAE: CPUInstruction.init(mnemonic: "LDX", cycles: 4, bytes: 3, addressingMode: .absolute,              action: Opcodes.LDX),
    0xBE: CPUInstruction.init(mnemonic: "LDX", cycles: 4, bytes: 3, addressingMode: .absolute_indexed_y,    action: Opcodes.LDX),
    
    0xA0: CPUInstruction.init(mnemonic: "LDY", cycles: 2, bytes: 2, addressingMode: .immediate,             action: Opcodes.LDY),
    0xA4: CPUInstruction.init(mnemonic: "LDY", cycles: 3, bytes: 2, addressingMode: .zeropage,              action: Opcodes.LDY),
    0xB4: CPUInstruction.init(mnemonic: "LDY", cycles: 4, bytes: 2, addressingMode: .zeropage_indexed_x,    action: Opcodes.LDY),
    0xAC: CPUInstruction.init(mnemonic: "LDY", cycles: 4, bytes: 3, addressingMode: .absolute,              action: Opcodes.LDY),
    0xBC: CPUInstruction.init(mnemonic: "LDY", cycles: 4, bytes: 3, addressingMode: .absolute_indexed_x,    action: Opcodes.LDY),
    
    //Register functions
    0x88: CPUInstruction.init(mnemonic: "DEY", cycles: 2, bytes: 1, addressingMode: .implied,               action: Opcodes.DEY),
    0x8A: CPUInstruction.init(mnemonic: "TXA", cycles: 2, bytes: 1, addressingMode: .implied,               action: Opcodes.TXA),
    0x98: CPUInstruction.init(mnemonic: "TYA", cycles: 2, bytes: 1, addressingMode: .implied,               action: Opcodes.TYA),
    0xA8: CPUInstruction.init(mnemonic: "TAY", cycles: 2, bytes: 1, addressingMode: .implied,               action: Opcodes.TAY),
    0xAA: CPUInstruction.init(mnemonic: "TAX", cycles: 2, bytes: 1, addressingMode: .implied,               action: Opcodes.TAX),
    0xC8: CPUInstruction.init(mnemonic: "INY", cycles: 2, bytes: 1, addressingMode: .implied,               action: Opcodes.INY),
    0xCA: CPUInstruction.init(mnemonic: "DEX", cycles: 2, bytes: 1, addressingMode: .implied,               action: Opcodes.DEX),
    0xE8: CPUInstruction.init(mnemonic: "INX", cycles: 2, bytes: 1, addressingMode: .implied,               action: Opcodes.INX),
    
    //Processor flag instructions
    0x18: CPUInstruction.init(mnemonic: "CLC", cycles: 2, bytes: 1, addressingMode: .implied,               action: Opcodes.CLC),
    0x38: CPUInstruction.init(mnemonic: "SEC", cycles: 2, bytes: 1, addressingMode: .implied,               action: Opcodes.SEC),
    0x58: CPUInstruction.init(mnemonic: "CLI", cycles: 2, bytes: 1, addressingMode: .implied,               action: Opcodes.CLI),
    0x78: CPUInstruction.init(mnemonic: "SEI", cycles: 2, bytes: 1, addressingMode: .implied,               action: Opcodes.SEI),
    0xB8: CPUInstruction.init(mnemonic: "CLV", cycles: 2, bytes: 1, addressingMode: .implied,               action: Opcodes.CLV),
    0xD8: CPUInstruction.init(mnemonic: "CLD", cycles: 2, bytes: 1, addressingMode: .implied,               action: Opcodes.CLD),
    0xF8: CPUInstruction.init(mnemonic: "SED", cycles: 2, bytes: 1, addressingMode: .implied,               action: Opcodes.SED),
    
    //Stack instructions
    0x9A: CPUInstruction.init(mnemonic: "TXS", cycles: 2, bytes: 1, addressingMode: .implied,               action: Opcodes.TXS),
    0xBA: CPUInstruction.init(mnemonic: "TSX", cycles: 2, bytes: 1, addressingMode: .implied,               action: Opcodes.TSX),
    0x48: CPUInstruction.init(mnemonic: "PHA", cycles: 3, bytes: 1, addressingMode: .implied,               action: Opcodes.PHA),
    0x68: CPUInstruction.init(mnemonic: "PLA", cycles: 4, bytes: 1, addressingMode: .implied,               action: Opcodes.PLA),
    0x08: CPUInstruction.init(mnemonic: "PHP", cycles: 3, bytes: 1, addressingMode: .implied,               action: Opcodes.PHP),
    0x28: CPUInstruction.init(mnemonic: "PLP", cycles: 4, bytes: 1, addressingMode: .implied,               action: Opcodes.PLP),
    
    0xEA: CPUInstruction.init(mnemonic: "NOP", cycles: 2, bytes: 1, addressingMode: .implied,               action: Opcodes.NOP),
]

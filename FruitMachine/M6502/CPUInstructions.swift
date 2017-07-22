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
    
    //INC/DEC
    0xC6: CPUInstruction(mnemonic: "DEC", cycles: 5, bytes: 2, addressingMode: .zeropage,              action: Opcodes.DEC),
    0xD6: CPUInstruction(mnemonic: "DEC", cycles: 6, bytes: 2, addressingMode: .zeropage_indexed_x,    action: Opcodes.DEC),
    0xCE: CPUInstruction(mnemonic: "DEC", cycles: 6, bytes: 3, addressingMode: .absolute,              action: Opcodes.DEC),
    0xDE: CPUInstruction(mnemonic: "DEC", cycles: 7, bytes: 3, addressingMode: .absolute_indexed_x,    action: Opcodes.DEC),
    
    0xE6: CPUInstruction(mnemonic: "INC", cycles: 5, bytes: 2, addressingMode: .zeropage,              action: Opcodes.INC),
    0xF6: CPUInstruction(mnemonic: "INC", cycles: 6, bytes: 2, addressingMode: .zeropage_indexed_x,    action: Opcodes.INC),
    0xEE: CPUInstruction(mnemonic: "INC", cycles: 6, bytes: 3, addressingMode: .absolute,              action: Opcodes.INC),
    0xFE: CPUInstruction(mnemonic: "INC", cycles: 7, bytes: 3, addressingMode: .absolute_indexed_x,    action: Opcodes.INC),
    
    //JMP
    0x4C: CPUInstruction(mnemonic: "JMP", cycles: 3, bytes: 3, addressingMode: .absolute,              action: Opcodes.JMP),
    0x6C: CPUInstruction(mnemonic: "JMP", cycles: 5, bytes: 3, addressingMode: .indirect,              action: Opcodes.JMP),
    
    //LD instructions
    0xA9: CPUInstruction(mnemonic: "LDA", cycles: 2, bytes: 2, addressingMode: .immediate,             action: Opcodes.LDA),
    0xA5: CPUInstruction(mnemonic: "LDA", cycles: 3, bytes: 2, addressingMode: .zeropage,              action: Opcodes.LDA),
    0xB5: CPUInstruction(mnemonic: "LDA", cycles: 4, bytes: 2, addressingMode: .zeropage_indexed_x,    action: Opcodes.LDA),
    0xAD: CPUInstruction(mnemonic: "LDA", cycles: 4, bytes: 3, addressingMode: .absolute,              action: Opcodes.LDA),
    0xBD: CPUInstruction(mnemonic: "LDA", cycles: 4, bytes: 3, addressingMode: .absolute_indexed_x,    action: Opcodes.LDA),
    0xB9: CPUInstruction(mnemonic: "LDA", cycles: 4, bytes: 3, addressingMode: .absolute_indexed_y,    action: Opcodes.LDA),
    0xA1: CPUInstruction(mnemonic: "LDA", cycles: 6, bytes: 2, addressingMode: .indexed_indirect,      action: Opcodes.LDA),
    0xB1: CPUInstruction(mnemonic: "LDA", cycles: 5, bytes: 2, addressingMode: .indirect_indexed,      action: Opcodes.LDA),
    
    0xA2: CPUInstruction(mnemonic: "LDX", cycles: 2, bytes: 2, addressingMode: .immediate,             action: Opcodes.LDX),
    0xA6: CPUInstruction(mnemonic: "LDX", cycles: 3, bytes: 2, addressingMode: .zeropage,              action: Opcodes.LDX),
    0xB6: CPUInstruction(mnemonic: "LDX", cycles: 4, bytes: 2, addressingMode: .zeropage_indexed_y,    action: Opcodes.LDX),
    0xAE: CPUInstruction(mnemonic: "LDX", cycles: 4, bytes: 3, addressingMode: .absolute,              action: Opcodes.LDX),
    0xBE: CPUInstruction(mnemonic: "LDX", cycles: 4, bytes: 3, addressingMode: .absolute_indexed_y,    action: Opcodes.LDX),
    
    0xA0: CPUInstruction(mnemonic: "LDY", cycles: 2, bytes: 2, addressingMode: .immediate,             action: Opcodes.LDY),
    0xA4: CPUInstruction(mnemonic: "LDY", cycles: 3, bytes: 2, addressingMode: .zeropage,              action: Opcodes.LDY),
    0xB4: CPUInstruction(mnemonic: "LDY", cycles: 4, bytes: 2, addressingMode: .zeropage_indexed_x,    action: Opcodes.LDY),
    0xAC: CPUInstruction(mnemonic: "LDY", cycles: 4, bytes: 3, addressingMode: .absolute,              action: Opcodes.LDY),
    0xBC: CPUInstruction(mnemonic: "LDY", cycles: 4, bytes: 3, addressingMode: .absolute_indexed_x,    action: Opcodes.LDY),
    
    //ST functions
    0x85: CPUInstruction(mnemonic: "STA", cycles: 3, bytes: 2, addressingMode: .zeropage,              action: Opcodes.STA),
    0x95: CPUInstruction(mnemonic: "STA", cycles: 4, bytes: 2, addressingMode: .zeropage_indexed_x,    action: Opcodes.STA),
    0x8D: CPUInstruction(mnemonic: "STA", cycles: 4, bytes: 3, addressingMode: .absolute,              action: Opcodes.STA),
    0x9D: CPUInstruction(mnemonic: "STA", cycles: 5, bytes: 3, addressingMode: .absolute_indexed_x,    action: Opcodes.STA),
    0x99: CPUInstruction(mnemonic: "STA", cycles: 5, bytes: 3, addressingMode: .absolute_indexed_y,    action: Opcodes.STA),
    0x81: CPUInstruction(mnemonic: "STA", cycles: 6, bytes: 2, addressingMode: .indexed_indirect,      action: Opcodes.STA),
    0x91: CPUInstruction(mnemonic: "STA", cycles: 6, bytes: 2, addressingMode: .indirect_indexed,      action: Opcodes.STA),
    
    //Register functions
    0x88: CPUInstruction(mnemonic: "DEY", cycles: 2, bytes: 1, addressingMode: .implied,               action: Opcodes.DEY),
    0x8A: CPUInstruction(mnemonic: "TXA", cycles: 2, bytes: 1, addressingMode: .implied,               action: Opcodes.TXA),
    0x98: CPUInstruction(mnemonic: "TYA", cycles: 2, bytes: 1, addressingMode: .implied,               action: Opcodes.TYA),
    0xA8: CPUInstruction(mnemonic: "TAY", cycles: 2, bytes: 1, addressingMode: .implied,               action: Opcodes.TAY),
    0xAA: CPUInstruction(mnemonic: "TAX", cycles: 2, bytes: 1, addressingMode: .implied,               action: Opcodes.TAX),
    0xC8: CPUInstruction(mnemonic: "INY", cycles: 2, bytes: 1, addressingMode: .implied,               action: Opcodes.INY),
    0xCA: CPUInstruction(mnemonic: "DEX", cycles: 2, bytes: 1, addressingMode: .implied,               action: Opcodes.DEX),
    0xE8: CPUInstruction(mnemonic: "INX", cycles: 2, bytes: 1, addressingMode: .implied,               action: Opcodes.INX),
    
    //Processor flag instructions
    0x18: CPUInstruction(mnemonic: "CLC", cycles: 2, bytes: 1, addressingMode: .implied,               action: Opcodes.CLC),
    0x38: CPUInstruction(mnemonic: "SEC", cycles: 2, bytes: 1, addressingMode: .implied,               action: Opcodes.SEC),
    0x58: CPUInstruction(mnemonic: "CLI", cycles: 2, bytes: 1, addressingMode: .implied,               action: Opcodes.CLI),
    0x78: CPUInstruction(mnemonic: "SEI", cycles: 2, bytes: 1, addressingMode: .implied,               action: Opcodes.SEI),
    0xB8: CPUInstruction(mnemonic: "CLV", cycles: 2, bytes: 1, addressingMode: .implied,               action: Opcodes.CLV),
    0xD8: CPUInstruction(mnemonic: "CLD", cycles: 2, bytes: 1, addressingMode: .implied,               action: Opcodes.CLD),
    0xF8: CPUInstruction(mnemonic: "SED", cycles: 2, bytes: 1, addressingMode: .implied,               action: Opcodes.SED),
    
    //Stack instructions
    0x9A: CPUInstruction(mnemonic: "TXS", cycles: 2, bytes: 1, addressingMode: .implied,               action: Opcodes.TXS),
    0xBA: CPUInstruction(mnemonic: "TSX", cycles: 2, bytes: 1, addressingMode: .implied,               action: Opcodes.TSX),
    0x48: CPUInstruction(mnemonic: "PHA", cycles: 3, bytes: 1, addressingMode: .implied,               action: Opcodes.PHA),
    0x68: CPUInstruction(mnemonic: "PLA", cycles: 4, bytes: 1, addressingMode: .implied,               action: Opcodes.PLA),
    0x08: CPUInstruction(mnemonic: "PHP", cycles: 3, bytes: 1, addressingMode: .implied,               action: Opcodes.PHP),
    0x28: CPUInstruction(mnemonic: "PLP", cycles: 4, bytes: 1, addressingMode: .implied,               action: Opcodes.PLP),
    
    0xEA: CPUInstruction(mnemonic: "NOP", cycles: 2, bytes: 1, addressingMode: .implied,               action: Opcodes.NOP),
]

//
//  CPUInstructions.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 7/20/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

final class CPUInstruction: NSObject {    
    let mnemonic: String    //The mnemonic for this instruction.
    let cycles: Int         //How many cycles does this instruction take?
    let bytes: Int          //How many bytes long is this instruction?
    let addressingMode: CPU.AddressingMode //The addressing mode of this instruction.
    
    let action: (CPU, CPU.AddressingMode) -> Void //A closure that describes this function's action.
    
    init(mnemonic: String, cycles: Int, bytes: Int, addressingMode: CPU.AddressingMode, action: @escaping (CPU, CPU.AddressingMode) -> Void) {
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
    
    //ADC/SBC
    0x69: CPUInstruction(mnemonic: "ADC", cycles: 2, bytes: 2, addressingMode: .immediate,              action: Opcodes.ADC),
    0x65: CPUInstruction(mnemonic: "ADC", cycles: 3, bytes: 2, addressingMode: .zeropage,               action: Opcodes.ADC),
    0x75: CPUInstruction(mnemonic: "ADC", cycles: 4, bytes: 2, addressingMode: .zeropage_indexed_x,     action: Opcodes.ADC),
    0x6D: CPUInstruction(mnemonic: "ADC", cycles: 4, bytes: 3, addressingMode: .absolute,               action: Opcodes.ADC),
    0x7D: CPUInstruction(mnemonic: "ADC", cycles: 4, bytes: 3, addressingMode: .absolute_indexed_x,     action: Opcodes.ADC),
    0x79: CPUInstruction(mnemonic: "ADC", cycles: 4, bytes: 3, addressingMode: .absolute_indexed_y,     action: Opcodes.ADC),
    0x61: CPUInstruction(mnemonic: "ADC", cycles: 6, bytes: 2, addressingMode: .indexed_indirect,       action: Opcodes.ADC),
    0x71: CPUInstruction(mnemonic: "ADC", cycles: 5, bytes: 2, addressingMode: .indirect_indexed,       action: Opcodes.ADC),
    
    0xE9: CPUInstruction(mnemonic: "SBC", cycles: 2, bytes: 2, addressingMode: .immediate,              action: Opcodes.SBC),
    0xE5: CPUInstruction(mnemonic: "SBC", cycles: 3, bytes: 2, addressingMode: .zeropage,               action: Opcodes.SBC),
    0xF5: CPUInstruction(mnemonic: "SBC", cycles: 4, bytes: 2, addressingMode: .zeropage_indexed_x,     action: Opcodes.SBC),
    0xED: CPUInstruction(mnemonic: "SBC", cycles: 4, bytes: 3, addressingMode: .absolute,               action: Opcodes.SBC),
    0xFD: CPUInstruction(mnemonic: "SBC", cycles: 4, bytes: 3, addressingMode: .absolute_indexed_x,     action: Opcodes.SBC),
    0xF9: CPUInstruction(mnemonic: "SBC", cycles: 4, bytes: 3, addressingMode: .absolute_indexed_y,     action: Opcodes.SBC),
    0xE1: CPUInstruction(mnemonic: "SBC", cycles: 6, bytes: 2, addressingMode: .indexed_indirect,       action: Opcodes.SBC),
    0xF1: CPUInstruction(mnemonic: "SBC", cycles: 5, bytes: 2, addressingMode: .indirect_indexed,       action: Opcodes.SBC),
    
    //Boolean operators
    0x09: CPUInstruction(mnemonic: "ORA", cycles: 2, bytes: 2, addressingMode: .immediate,              action: Opcodes.ORA),
    0x05: CPUInstruction(mnemonic: "ORA", cycles: 3, bytes: 2, addressingMode: .zeropage,               action: Opcodes.ORA),
    0x15: CPUInstruction(mnemonic: "ORA", cycles: 4, bytes: 2, addressingMode: .zeropage_indexed_x,     action: Opcodes.ORA),
    0x0D: CPUInstruction(mnemonic: "ORA", cycles: 4, bytes: 3, addressingMode: .absolute,               action: Opcodes.ORA),
    0x1D: CPUInstruction(mnemonic: "ORA", cycles: 4, bytes: 3, addressingMode: .absolute_indexed_x,     action: Opcodes.ORA),
    0x19: CPUInstruction(mnemonic: "ORA", cycles: 4, bytes: 3, addressingMode: .absolute_indexed_y,     action: Opcodes.ORA),
    0x01: CPUInstruction(mnemonic: "ORA", cycles: 6, bytes: 2, addressingMode: .indexed_indirect,       action: Opcodes.ORA),
    0x11: CPUInstruction(mnemonic: "ORA", cycles: 5, bytes: 2, addressingMode: .indirect_indexed,       action: Opcodes.ORA),
    
    0x49: CPUInstruction(mnemonic: "EOR", cycles: 2, bytes: 2, addressingMode: .immediate,              action: Opcodes.EOR),
    0x45: CPUInstruction(mnemonic: "EOR", cycles: 3, bytes: 2, addressingMode: .zeropage,               action: Opcodes.EOR),
    0x55: CPUInstruction(mnemonic: "EOR", cycles: 4, bytes: 2, addressingMode: .zeropage_indexed_x,     action: Opcodes.EOR),
    0x4D: CPUInstruction(mnemonic: "EOR", cycles: 4, bytes: 3, addressingMode: .absolute,               action: Opcodes.EOR),
    0x5D: CPUInstruction(mnemonic: "EOR", cycles: 4, bytes: 3, addressingMode: .absolute_indexed_x,     action: Opcodes.EOR),
    0x59: CPUInstruction(mnemonic: "EOR", cycles: 4, bytes: 3, addressingMode: .absolute_indexed_y,     action: Opcodes.EOR),
    0x41: CPUInstruction(mnemonic: "EOR", cycles: 6, bytes: 2, addressingMode: .indexed_indirect,       action: Opcodes.EOR),
    0x51: CPUInstruction(mnemonic: "EOR", cycles: 5, bytes: 2, addressingMode: .indirect_indexed,       action: Opcodes.EOR),
    
    0x29: CPUInstruction(mnemonic: "AND", cycles: 2, bytes: 2, addressingMode: .immediate,              action: Opcodes.AND),
    0x25: CPUInstruction(mnemonic: "AND", cycles: 3, bytes: 2, addressingMode: .zeropage,               action: Opcodes.AND),
    0x35: CPUInstruction(mnemonic: "AND", cycles: 4, bytes: 2, addressingMode: .zeropage_indexed_x,     action: Opcodes.AND),
    0x2D: CPUInstruction(mnemonic: "AND", cycles: 4, bytes: 3, addressingMode: .absolute,               action: Opcodes.AND),
    0x3D: CPUInstruction(mnemonic: "AND", cycles: 4, bytes: 3, addressingMode: .absolute_indexed_x,     action: Opcodes.AND),
    0x39: CPUInstruction(mnemonic: "AND", cycles: 4, bytes: 3, addressingMode: .absolute_indexed_y,     action: Opcodes.AND),
    0x21: CPUInstruction(mnemonic: "AND", cycles: 6, bytes: 2, addressingMode: .indexed_indirect,       action: Opcodes.AND),
    0x31: CPUInstruction(mnemonic: "AND", cycles: 5, bytes: 2, addressingMode: .indirect_indexed,       action: Opcodes.AND),
    
    //Bitwise operations
    0x24: CPUInstruction(mnemonic: "BIT", cycles: 3, bytes: 2, addressingMode: .zeropage,               action: Opcodes.BIT),
    0x2C: CPUInstruction(mnemonic: "BIT", cycles: 4, bytes: 3, addressingMode: .absolute,               action: Opcodes.BIT),
    
    0x0A: CPUInstruction(mnemonic: "ASL", cycles: 2, bytes: 1, addressingMode: .accumulator,            action: Opcodes.ASL),
    0x06: CPUInstruction(mnemonic: "ASL", cycles: 5, bytes: 2, addressingMode: .zeropage,               action: Opcodes.ASL),
    0x16: CPUInstruction(mnemonic: "ASL", cycles: 6, bytes: 2, addressingMode: .zeropage_indexed_x,     action: Opcodes.ASL),
    0x0E: CPUInstruction(mnemonic: "ASL", cycles: 6, bytes: 3, addressingMode: .absolute,               action: Opcodes.ASL),
    0x1E: CPUInstruction(mnemonic: "ASL", cycles: 7, bytes: 3, addressingMode: .absolute_indexed_x,     action: Opcodes.ASL),
    
    0x4A: CPUInstruction(mnemonic: "LSR", cycles: 2, bytes: 1, addressingMode: .accumulator,            action: Opcodes.LSR),
    0x46: CPUInstruction(mnemonic: "LSR", cycles: 5, bytes: 2, addressingMode: .zeropage,               action: Opcodes.LSR),
    0x56: CPUInstruction(mnemonic: "LSR", cycles: 6, bytes: 2, addressingMode: .zeropage_indexed_x,     action: Opcodes.LSR),
    0x4E: CPUInstruction(mnemonic: "LSR", cycles: 6, bytes: 3, addressingMode: .absolute,               action: Opcodes.LSR),
    0x5E: CPUInstruction(mnemonic: "LSR", cycles: 7, bytes: 3, addressingMode: .absolute_indexed_x,     action: Opcodes.LSR),
    
    0x2A: CPUInstruction(mnemonic: "ROL", cycles: 2, bytes: 1, addressingMode: .accumulator,            action: Opcodes.ROL),
    0x26: CPUInstruction(mnemonic: "ROL", cycles: 5, bytes: 2, addressingMode: .zeropage,               action: Opcodes.ROL),
    0x36: CPUInstruction(mnemonic: "ROL", cycles: 6, bytes: 2, addressingMode: .zeropage_indexed_x,     action: Opcodes.ROL),
    0x2E: CPUInstruction(mnemonic: "ROL", cycles: 6, bytes: 3, addressingMode: .absolute,               action: Opcodes.ROL),
    0x3E: CPUInstruction(mnemonic: "ROL", cycles: 7, bytes: 3, addressingMode: .absolute_indexed_x,     action: Opcodes.ROL),
    
    0x6A: CPUInstruction(mnemonic: "ROR", cycles: 2, bytes: 1, addressingMode: .accumulator,            action: Opcodes.ROR),
    0x66: CPUInstruction(mnemonic: "ROR", cycles: 5, bytes: 2, addressingMode: .zeropage,               action: Opcodes.ROR),
    0x76: CPUInstruction(mnemonic: "ROR", cycles: 6, bytes: 2, addressingMode: .zeropage_indexed_x,     action: Opcodes.ROR),
    0x6E: CPUInstruction(mnemonic: "ROR", cycles: 6, bytes: 3, addressingMode: .absolute,               action: Opcodes.ROR),
    0x7E: CPUInstruction(mnemonic: "ROR", cycles: 7, bytes: 3, addressingMode: .absolute_indexed_x,     action: Opcodes.ROR),
    
    //INC/DEC
    0xC6: CPUInstruction(mnemonic: "DEC", cycles: 5, bytes: 2, addressingMode: .zeropage,               action: Opcodes.DEC),
    0xD6: CPUInstruction(mnemonic: "DEC", cycles: 6, bytes: 2, addressingMode: .zeropage_indexed_x,     action: Opcodes.DEC),
    0xCE: CPUInstruction(mnemonic: "DEC", cycles: 6, bytes: 3, addressingMode: .absolute,               action: Opcodes.DEC),
    0xDE: CPUInstruction(mnemonic: "DEC", cycles: 7, bytes: 3, addressingMode: .absolute_indexed_x,     action: Opcodes.DEC),
    
    0xE6: CPUInstruction(mnemonic: "INC", cycles: 5, bytes: 2, addressingMode: .zeropage,               action: Opcodes.INC),
    0xF6: CPUInstruction(mnemonic: "INC", cycles: 6, bytes: 2, addressingMode: .zeropage_indexed_x,     action: Opcodes.INC),
    0xEE: CPUInstruction(mnemonic: "INC", cycles: 6, bytes: 3, addressingMode: .absolute,               action: Opcodes.INC),
    0xFE: CPUInstruction(mnemonic: "INC", cycles: 7, bytes: 3, addressingMode: .absolute_indexed_x,     action: Opcodes.INC),
    
    //JMP
    0x4C: CPUInstruction(mnemonic: "JMP", cycles: 3, bytes: 3, addressingMode: .absolute,               action: Opcodes.JMP),
    0x6C: CPUInstruction(mnemonic: "JMP", cycles: 5, bytes: 3, addressingMode: .indirect,               action: Opcodes.JMP),
    
    //LD instructions
    0xA9: CPUInstruction(mnemonic: "LDA", cycles: 2, bytes: 2, addressingMode: .immediate,              action: Opcodes.LDA),
    0xA5: CPUInstruction(mnemonic: "LDA", cycles: 3, bytes: 2, addressingMode: .zeropage,               action: Opcodes.LDA),
    0xB5: CPUInstruction(mnemonic: "LDA", cycles: 4, bytes: 2, addressingMode: .zeropage_indexed_x,     action: Opcodes.LDA),
    0xAD: CPUInstruction(mnemonic: "LDA", cycles: 4, bytes: 3, addressingMode: .absolute,               action: Opcodes.LDA),
    0xBD: CPUInstruction(mnemonic: "LDA", cycles: 4, bytes: 3, addressingMode: .absolute_indexed_x,     action: Opcodes.LDA),
    0xB9: CPUInstruction(mnemonic: "LDA", cycles: 4, bytes: 3, addressingMode: .absolute_indexed_y,     action: Opcodes.LDA),
    0xA1: CPUInstruction(mnemonic: "LDA", cycles: 6, bytes: 2, addressingMode: .indexed_indirect,       action: Opcodes.LDA),
    0xB1: CPUInstruction(mnemonic: "LDA", cycles: 5, bytes: 2, addressingMode: .indirect_indexed,       action: Opcodes.LDA),
    
    0xA2: CPUInstruction(mnemonic: "LDX", cycles: 2, bytes: 2, addressingMode: .immediate,              action: Opcodes.LDX),
    0xA6: CPUInstruction(mnemonic: "LDX", cycles: 3, bytes: 2, addressingMode: .zeropage,               action: Opcodes.LDX),
    0xB6: CPUInstruction(mnemonic: "LDX", cycles: 4, bytes: 2, addressingMode: .zeropage_indexed_y,     action: Opcodes.LDX),
    0xAE: CPUInstruction(mnemonic: "LDX", cycles: 4, bytes: 3, addressingMode: .absolute,               action: Opcodes.LDX),
    0xBE: CPUInstruction(mnemonic: "LDX", cycles: 4, bytes: 3, addressingMode: .absolute_indexed_y,     action: Opcodes.LDX),
    
    0xA0: CPUInstruction(mnemonic: "LDY", cycles: 2, bytes: 2, addressingMode: .immediate,              action: Opcodes.LDY),
    0xA4: CPUInstruction(mnemonic: "LDY", cycles: 3, bytes: 2, addressingMode: .zeropage,               action: Opcodes.LDY),
    0xB4: CPUInstruction(mnemonic: "LDY", cycles: 4, bytes: 2, addressingMode: .zeropage_indexed_x,     action: Opcodes.LDY),
    0xAC: CPUInstruction(mnemonic: "LDY", cycles: 4, bytes: 3, addressingMode: .absolute,               action: Opcodes.LDY),
    0xBC: CPUInstruction(mnemonic: "LDY", cycles: 4, bytes: 3, addressingMode: .absolute_indexed_x,     action: Opcodes.LDY),
    
    //ST functions
    0x85: CPUInstruction(mnemonic: "STA", cycles: 3, bytes: 2, addressingMode: .zeropage,               action: Opcodes.STA),
    0x95: CPUInstruction(mnemonic: "STA", cycles: 4, bytes: 2, addressingMode: .zeropage_indexed_x,     action: Opcodes.STA),
    0x8D: CPUInstruction(mnemonic: "STA", cycles: 4, bytes: 3, addressingMode: .absolute,               action: Opcodes.STA),
    0x9D: CPUInstruction(mnemonic: "STA", cycles: 5, bytes: 3, addressingMode: .absolute_indexed_x,     action: Opcodes.STA),
    0x99: CPUInstruction(mnemonic: "STA", cycles: 5, bytes: 3, addressingMode: .absolute_indexed_y,     action: Opcodes.STA),
    0x81: CPUInstruction(mnemonic: "STA", cycles: 6, bytes: 2, addressingMode: .indexed_indirect,       action: Opcodes.STA),
    0x91: CPUInstruction(mnemonic: "STA", cycles: 6, bytes: 2, addressingMode: .indirect_indexed,       action: Opcodes.STA),
    
    0x86: CPUInstruction(mnemonic: "STX", cycles: 3, bytes: 2, addressingMode: .zeropage,               action: Opcodes.STX),
    0x96: CPUInstruction(mnemonic: "STX", cycles: 4, bytes: 2, addressingMode: .zeropage_indexed_y,     action: Opcodes.STX),
    0x8E: CPUInstruction(mnemonic: "STX", cycles: 4, bytes: 3, addressingMode: .absolute,               action: Opcodes.STX),
    
    0x84: CPUInstruction(mnemonic: "STY", cycles: 3, bytes: 2, addressingMode: .zeropage,               action: Opcodes.STY),
    0x94: CPUInstruction(mnemonic: "STY", cycles: 4, bytes: 2, addressingMode: .zeropage_indexed_x,     action: Opcodes.STY),
    0x8C: CPUInstruction(mnemonic: "STY", cycles: 4, bytes: 3, addressingMode: .absolute,               action: Opcodes.STY),
    
    //Compare functions
    0xC9: CPUInstruction(mnemonic: "CMP", cycles: 2, bytes: 2, addressingMode: .immediate,              action: Opcodes.CMP),
    0xC5: CPUInstruction(mnemonic: "CMP", cycles: 3, bytes: 2, addressingMode: .zeropage,               action: Opcodes.CMP),
    0xD5: CPUInstruction(mnemonic: "CMP", cycles: 4, bytes: 2, addressingMode: .zeropage_indexed_x,     action: Opcodes.CMP),
    0xCD: CPUInstruction(mnemonic: "CMP", cycles: 4, bytes: 3, addressingMode: .absolute,               action: Opcodes.CMP),
    0xDD: CPUInstruction(mnemonic: "CMP", cycles: 4, bytes: 3, addressingMode: .absolute_indexed_x,     action: Opcodes.CMP),
    0xD9: CPUInstruction(mnemonic: "CMP", cycles: 4, bytes: 3, addressingMode: .absolute_indexed_y,     action: Opcodes.CMP),
    0xC1: CPUInstruction(mnemonic: "CMP", cycles: 6, bytes: 2, addressingMode: .indexed_indirect,       action: Opcodes.CMP),
    0xD1: CPUInstruction(mnemonic: "CMP", cycles: 5, bytes: 2, addressingMode: .indirect_indexed,       action: Opcodes.CMP),
    
    0xE0: CPUInstruction(mnemonic: "CPX", cycles: 2, bytes: 2, addressingMode: .immediate,              action: Opcodes.CPX),
    0xE4: CPUInstruction(mnemonic: "CPX", cycles: 3, bytes: 2, addressingMode: .zeropage,               action: Opcodes.CPX),
    0xEC: CPUInstruction(mnemonic: "CPX", cycles: 4, bytes: 3, addressingMode: .absolute,               action: Opcodes.CPX),
    
    0xC0: CPUInstruction(mnemonic: "CPY", cycles: 2, bytes: 2, addressingMode: .immediate,              action: Opcodes.CPY),
    0xC4: CPUInstruction(mnemonic: "CPY", cycles: 3, bytes: 2, addressingMode: .zeropage,               action: Opcodes.CPY),
    0xCC: CPUInstruction(mnemonic: "CPY", cycles: 4, bytes: 3, addressingMode: .absolute,               action: Opcodes.CPY),
    
    //Register functions
    0x88: CPUInstruction(mnemonic: "DEY", cycles: 2, bytes: 1, addressingMode: .implied,                action: Opcodes.DEY),
    0x8A: CPUInstruction(mnemonic: "TXA", cycles: 2, bytes: 1, addressingMode: .implied,                action: Opcodes.TXA),
    0x98: CPUInstruction(mnemonic: "TYA", cycles: 2, bytes: 1, addressingMode: .implied,                action: Opcodes.TYA),
    0xA8: CPUInstruction(mnemonic: "TAY", cycles: 2, bytes: 1, addressingMode: .implied,                action: Opcodes.TAY),
    0xAA: CPUInstruction(mnemonic: "TAX", cycles: 2, bytes: 1, addressingMode: .implied,                action: Opcodes.TAX),
    0xC8: CPUInstruction(mnemonic: "INY", cycles: 2, bytes: 1, addressingMode: .implied,                action: Opcodes.INY),
    0xCA: CPUInstruction(mnemonic: "DEX", cycles: 2, bytes: 1, addressingMode: .implied,                action: Opcodes.DEX),
    0xE8: CPUInstruction(mnemonic: "INX", cycles: 2, bytes: 1, addressingMode: .implied,                action: Opcodes.INX),
    
    //Processor flag instructions
    0x18: CPUInstruction(mnemonic: "CLC", cycles: 2, bytes: 1, addressingMode: .implied,                action: Opcodes.CLC),
    0x38: CPUInstruction(mnemonic: "SEC", cycles: 2, bytes: 1, addressingMode: .implied,                action: Opcodes.SEC),
    0x58: CPUInstruction(mnemonic: "CLI", cycles: 2, bytes: 1, addressingMode: .implied,                action: Opcodes.CLI),
    0x78: CPUInstruction(mnemonic: "SEI", cycles: 2, bytes: 1, addressingMode: .implied,                action: Opcodes.SEI),
    0xB8: CPUInstruction(mnemonic: "CLV", cycles: 2, bytes: 1, addressingMode: .implied,                action: Opcodes.CLV),
    0xD8: CPUInstruction(mnemonic: "CLD", cycles: 2, bytes: 1, addressingMode: .implied,                action: Opcodes.CLD),
    0xF8: CPUInstruction(mnemonic: "SED", cycles: 2, bytes: 1, addressingMode: .implied,                action: Opcodes.SED),
    
    //Stack instructions
    0x9A: CPUInstruction(mnemonic: "TXS", cycles: 2, bytes: 1, addressingMode: .implied,                action: Opcodes.TXS),
    0xBA: CPUInstruction(mnemonic: "TSX", cycles: 2, bytes: 1, addressingMode: .implied,                action: Opcodes.TSX),
    0x48: CPUInstruction(mnemonic: "PHA", cycles: 3, bytes: 1, addressingMode: .implied,                action: Opcodes.PHA),
    0x68: CPUInstruction(mnemonic: "PLA", cycles: 4, bytes: 1, addressingMode: .implied,                action: Opcodes.PLA),
    0x08: CPUInstruction(mnemonic: "PHP", cycles: 3, bytes: 1, addressingMode: .implied,                action: Opcodes.PHP),
    0x28: CPUInstruction(mnemonic: "PLP", cycles: 4, bytes: 1, addressingMode: .implied,                action: Opcodes.PLP),
    
    //Branch instructions
    0x10: CPUInstruction(mnemonic: "BPL", cycles: 2, bytes: 2, addressingMode: .relative,               action: Opcodes.BPL),
    0x30: CPUInstruction(mnemonic: "BMI", cycles: 2, bytes: 2, addressingMode: .relative,               action: Opcodes.BMI),
    0x50: CPUInstruction(mnemonic: "BVC", cycles: 2, bytes: 2, addressingMode: .relative,               action: Opcodes.BVC),
    0x70: CPUInstruction(mnemonic: "BVS", cycles: 2, bytes: 2, addressingMode: .relative,               action: Opcodes.BVS),
    0x90: CPUInstruction(mnemonic: "BCC", cycles: 2, bytes: 2, addressingMode: .relative,               action: Opcodes.BCC),
    0xB0: CPUInstruction(mnemonic: "BCS", cycles: 2, bytes: 2, addressingMode: .relative,               action: Opcodes.BCS),
    0xD0: CPUInstruction(mnemonic: "BNE", cycles: 2, bytes: 2, addressingMode: .relative,               action: Opcodes.BNE),
    0xF0: CPUInstruction(mnemonic: "BEQ", cycles: 2, bytes: 2, addressingMode: .relative,               action: Opcodes.BEQ),
    
    0x20: CPUInstruction(mnemonic: "JSR", cycles: 6, bytes: 3, addressingMode: .absolute,               action: Opcodes.JSR),
    0x40: CPUInstruction(mnemonic: "RTI", cycles: 6, bytes: 1, addressingMode: .implied,                action: Opcodes.RTI),
    0x60: CPUInstruction(mnemonic: "RTS", cycles: 6, bytes: 1, addressingMode: .implied,                action: Opcodes.RTS),
    
    0x00: CPUInstruction(mnemonic: "BRK", cycles: 7, bytes: 1, addressingMode: .implied,                action: Opcodes.BRK),
    
    0xEA: CPUInstruction(mnemonic: "NOP", cycles: 2, bytes: 1, addressingMode: .implied,                action: Opcodes.NOP),

    //Illegal opcodes
    0x1A: CPUInstruction(mnemonic: "NOP", cycles: 2, bytes: 1, addressingMode: .implied,                action: Opcodes.NOP),
    0x3A: CPUInstruction(mnemonic: "NOP", cycles: 2, bytes: 1, addressingMode: .implied,                action: Opcodes.NOP),
    0x5A: CPUInstruction(mnemonic: "NOP", cycles: 2, bytes: 1, addressingMode: .implied,                action: Opcodes.NOP),
    0x7A: CPUInstruction(mnemonic: "NOP", cycles: 2, bytes: 1, addressingMode: .implied,                action: Opcodes.NOP),
    0xDA: CPUInstruction(mnemonic: "NOP", cycles: 2, bytes: 1, addressingMode: .implied,                action: Opcodes.NOP),
    0xFA: CPUInstruction(mnemonic: "NOP", cycles: 2, bytes: 1, addressingMode: .implied,                action: Opcodes.NOP),
    0x82: CPUInstruction(mnemonic: "NOP", cycles: 2, bytes: 2, addressingMode: .implied,                action: Opcodes.NOP),
    0xC2: CPUInstruction(mnemonic: "NOP", cycles: 2, bytes: 2, addressingMode: .implied,                action: Opcodes.NOP),
    0xE2: CPUInstruction(mnemonic: "NOP", cycles: 2, bytes: 2, addressingMode: .implied,                action: Opcodes.NOP),
    
    //0x07: CPUInstruction(mnemonic: "SLO", cycles: 5, bytes: 2, addressingMode: .zeropage,               action: Opcodes.SLO),
]

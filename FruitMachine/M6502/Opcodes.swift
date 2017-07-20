//
//  Opcodes.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 7/20/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

/* Addressing mode helper functions */
func PC_PLUS_1(state: CPUState) -> UInt16 {
    return state.program_counter + 1
}

func OPERAND_IMMEDIATE(state: CPUState) -> UInt8 {
    //Operand = PC+1
    return MEMORY_READ_UINT8(state: state, address: state.program_counter + 1)
}

func OPERAND_ZEROPAGE_INDEXED_X(state: CPUState) -> UInt8 {
    //Operand = (PC+1) + X
    return MEMORY_READ_UINT8(state: state, address: (state.program_counter + 1) + UInt16(state.index_x))
}

func OPERAND_ZEROPAGE_INDEXED_Y(state: CPUState) -> UInt8 {
    //Operand = (PC+1) + Y
    return MEMORY_READ_UINT8(state: state, address: (state.program_counter + 1) + UInt16(state.index_y))
}

func OPERAND_ABSOLUTE(state: CPUState) -> UInt16 {
    //Operand = L:(PC+1) H:(PC+2)
    let low: UInt8  = MEMORY_READ_UINT8(state: state, address: state.program_counter + 1)
    let high: UInt8 = MEMORY_READ_UINT8(state: state, address: state.program_counter + 2)
    return UInt16(high << 8 | low)
}

func OPERAND_ABSOLUTE_INDEXED_X(state: CPUState) -> UInt16 {
    //Operand = L:(PC+1)+X H:(PC+2)+X    
    let low: UInt8  = MEMORY_READ_UINT8(state: state, address: state.program_counter + 1 + UInt16(state.index_x))
    let high: UInt8 = MEMORY_READ_UINT8(state: state, address: state.program_counter + 2 + UInt16(state.index_x))
    return UInt16(high << 8 | low)
}

func OPERAND_ABSOLUTE_INDEXED_Y(state: CPUState) -> UInt16 {
    //Operand = L:(PC+1)+Y H:(PC+2)+Y
    let low: UInt8  = MEMORY_READ_UINT8(state: state, address: state.program_counter + 1 + UInt16(state.index_y))
    let high: UInt8 = MEMORY_READ_UINT8(state: state, address: state.program_counter + 2 + UInt16(state.index_y))
    return UInt16(high << 8 | low)
}

func MEMORY_READ_UINT8(state: CPUState, address: UInt16) -> UInt8 {
    return state.memoryInterface.memory[Int(address)]
}

class Opcodes: NSObject {
    static func LDA(state: CPUState, addressingMode: AddressingMode) -> Void {
        
        switch addressingMode {
        case .immediate:
            state.accumulator = OPERAND_IMMEDIATE(state: state)
        case .zeropage:
            state.accumulator = OPERAND_ZEROPAGE_INDEXED_X(state: state)
        case .zeropage_indexed_x:
            state.accumulator = MEMORY_READ_UINT8(state: state, address: UInt16(0x0000 + OPERAND_ZEROPAGE_INDEXED_X(state: state)))
        case .absolute:
            state.accumulator = MEMORY_READ_UINT8(state: state, address: OPERAND_ABSOLUTE(state: state))
        case .absolute_indexed_x:
            state.accumulator = MEMORY_READ_UINT8(state: state, address: OPERAND_ABSOLUTE_INDEXED_X(state: state))
        case .absolute_indexed_y:
            state.accumulator = MEMORY_READ_UINT8(state: state, address: OPERAND_ABSOLUTE_INDEXED_Y(state: state))
        default:
            print("Unhandled addressing mode \(addressingMode) for LDA")
        }
        
        state.setZeroFlag();
        state.setNegativeFlag();
    }
}

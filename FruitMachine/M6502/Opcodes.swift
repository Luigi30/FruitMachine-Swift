//
//  Opcodes.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 7/20/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

func getOperand(state: CPUState, mode: AddressingMode) -> UInt8 {
    switch (mode) {
        
    case .immediate:
        return state.getOperandByte()
        
    case .zeropage:
        return state.memoryInterface.readByte(offset: UInt16(0x0000 + state.getOperandByte()))
    case .zeropage_indexed_x:
        return state.memoryInterface.readByte(offset: UInt16(state.getOperandByte() + state.index_x) & 0x00FF)
    case .zeropage_indexed_y:
        return state.memoryInterface.readByte(offset: UInt16(state.getOperandByte() + state.index_y) & 0x00FF)
        
    case .absolute:
        let word: UInt16 = state.getOperandWord()
        return state.memoryInterface.readByte(offset: word)
    case .absolute_indexed_x:
        return state.memoryInterface.readByte(offset: state.getOperandWord() + UInt16(state.index_x))
    case .absolute_indexed_y:
        return state.memoryInterface.readByte(offset: state.getOperandWord() + UInt16(state.index_y))
        
    case .indexed_indirect:
        let zp: UInt8 = state.memoryInterface.readByte(offset: UInt16(state.getOperandByte() + state.index_x))
        //read from (ZP)
        let pointer: UInt16 = state.memoryInterface.readWord(offset: UInt16(zp))
        state.accumulator = state.memoryInterface.readByte(offset: pointer)
    case .indirect_indexed:
        let zp: UInt8 = state.memoryInterface.readByte(offset: UInt16(state.getOperandByte()))
        let pointer: UInt16 = state.memoryInterface.readWord(offset: UInt16(zp)) + UInt16(state.index_y)
        state.accumulator = state.memoryInterface.readByte(offset: pointer)
        
    case .indirect:
        //JMP is the only instruction that does this - handle it specially since it's a UInt16
        break
    
    default:
        print("Called getOperand on an instruction in addressing mode \(mode)")
        return 0
    }
    
    return 0 //never gets here
}

/* */

class Opcodes: NSObject {
    
    static func LDA(state: CPUState, addressingMode: AddressingMode) -> Void {
        state.accumulator = getOperand(state: state, mode: addressingMode)
 
        state.updateZeroFlag()
        state.updateNegativeFlag()
    }
    
    static func LDX(state: CPUState, addressingMode: AddressingMode) -> Void {
        state.index_x = getOperand(state: state, mode: addressingMode)
        
        state.updateZeroFlag()
        state.updateNegativeFlag()
    }
    
    static func LDY(state: CPUState, addressingMode: AddressingMode) -> Void {
        state.index_y = getOperand(state: state, mode: addressingMode)
        
        state.updateZeroFlag()
        state.updateNegativeFlag()
    }
    
    //Register instructions
    static func TAX(state: CPUState, addressingMode: AddressingMode) -> Void {
        state.index_x = state.accumulator
        
        state.updateZeroFlag();
        state.updateNegativeFlag();
    }
    
    static func TXA(state: CPUState, addressingMode: AddressingMode) -> Void {
        state.accumulator = state.index_x
        
        state.updateZeroFlag();
        state.updateNegativeFlag();
    }
    
    static func DEX(state: CPUState, addressingMode: AddressingMode) -> Void {
        state.index_x = state.index_x &- 1
        
        state.updateZeroFlag();
        state.updateNegativeFlag();
    }
    
    static func INX(state: CPUState, addressingMode: AddressingMode) -> Void {
        state.index_x = state.index_x &+ 1
        
        state.updateZeroFlag();
        state.updateNegativeFlag();
    }
    
    static func TAY(state: CPUState, addressingMode: AddressingMode) -> Void {
        state.index_y = state.accumulator
        
        state.updateZeroFlag();
        state.updateNegativeFlag();
    }
    
    static func TYA(state: CPUState, addressingMode: AddressingMode) -> Void {
        state.accumulator = state.index_y
        
        state.updateZeroFlag();
        state.updateNegativeFlag();
    }
    
    static func DEY(state: CPUState, addressingMode: AddressingMode) -> Void {
        state.index_y = state.index_x &- 1
        
        state.updateZeroFlag();
        state.updateNegativeFlag();
    }
    
    static func INY(state: CPUState, addressingMode: AddressingMode) -> Void {
        state.index_y = state.index_x &+ 1
        
        state.updateZeroFlag();
        state.updateNegativeFlag();
    }
    
    //Processor flag instructions
    static func CLC(state: CPUState, addressingMode: AddressingMode) -> Void {
        state.status_register.carry = false
    }
    
    static func SEC(state: CPUState, addressingMode: AddressingMode) -> Void {
        state.status_register.carry = true
    }
    
    static func CLI(state: CPUState, addressingMode: AddressingMode) -> Void {
        state.status_register.irq_disable = false
    }
    
    static func SEI(state: CPUState, addressingMode: AddressingMode) -> Void {
        state.status_register.irq_disable = true
    }
    
    static func CLV(state: CPUState, addressingMode: AddressingMode) -> Void {
        state.status_register.overflow = false
    }
    
    static func CLD(state: CPUState, addressingMode: AddressingMode) -> Void {
        state.status_register.decimal = false
    }
    
    static func SED(state: CPUState, addressingMode: AddressingMode) -> Void {
        state.status_register.carry = true
    }
    
    //Stack instructions
    static func TXS(state: CPUState, addressingMode: AddressingMode) -> Void {
        state.stack_pointer = state.index_x
    }
    
    static func TSX(state: CPUState, addressingMode: AddressingMode) -> Void {
        state.index_x = state.stack_pointer
    }
    
    static func PHA(state: CPUState, addressingMode: AddressingMode) -> Void {
        state.memoryInterface.writeByte(offset: 0x0100 | UInt16(state.stack_pointer), value: state.accumulator)
        state.stack_pointer = state.stack_pointer &- 1
    }
    
    static func PLA(state: CPUState, addressingMode: AddressingMode) -> Void {
        state.stack_pointer = state.stack_pointer &+ 1
        state.accumulator = state.memoryInterface.readByte(offset: 0x0100 | UInt16(state.stack_pointer))
    }
    
    static func PHP(state: CPUState, addressingMode: AddressingMode) -> Void {
        state.memoryInterface.writeByte(offset: 0x0100 | UInt16(state.stack_pointer), value: state.status_register.asByte())
        state.stack_pointer = state.stack_pointer &- 1
    }
    
    static func PLP(state: CPUState, addressingMode: AddressingMode) -> Void {
        state.stack_pointer = state.stack_pointer &+ 1
        state.status_register.setState(state: state.memoryInterface.readByte(offset: 0x0100 | UInt16(state.stack_pointer)))
    }
    
    static func NOP(state: CPUState, addressingMode: AddressingMode) -> Void {}
}

//
//  Opcodes.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 7/20/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

func stackPointerAsUInt16(state: CPUState) -> UInt16 {
    return 0x0100 | UInt16(state.stack_pointer);
}

func zpAsUInt16(address: UInt8) -> UInt16 {
    return 0x0000 | UInt16(address)
}

func getOperandByteForAddressingMode(state: CPUState, mode: AddressingMode) -> UInt8 {
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
        return state.memoryInterface.readByte(offset: pointer)
    case .indirect_indexed:
        let zp: UInt8 = state.memoryInterface.readByte(offset: UInt16(state.getOperandByte()))
        let pointer: UInt16 = state.memoryInterface.readWord(offset: UInt16(zp)) + UInt16(state.index_y)
        return state.memoryInterface.readByte(offset: pointer)
    default:
        print("Called getOperand: UInt8 on an instruction that expects a UInt16.")
        return 0
    }
}

func getOperandWordForAddressingMode(state: CPUState, mode: AddressingMode) -> UInt16 {
    //Function that will provide a 16-bit operand to instructions.
    //All instructions have 2 data bytes, little-endian.
    
    switch(mode) {
    case .absolute:
        return state.getOperandWord()
    case .absolute_indexed_x:
        return state.getOperandWord() + state.index_x
    case .absolute_indexed_y:
        return state.getOperandWord() + state.index_y
    case .indirect:
        return state.memoryInterface.readWord(offset: state.getOperandWord())
    default:
        print("Called getOperand: UInt16 on an instruction that expects a UInt8")
        return 0
    }
    
}

/* */

class Opcodes: NSObject {
    
    static func LDA(state: CPUState, addressingMode: AddressingMode) -> Void {
        state.accumulator = getOperandByteForAddressingMode(state: state, mode: addressingMode)
 
        state.updateZeroFlag(value: state.accumulator)
        state.updateNegativeFlag(value: state.accumulator)
    }
    
    static func LDX(state: CPUState, addressingMode: AddressingMode) -> Void {
        state.index_x = getOperandByteForAddressingMode(state: state, mode: addressingMode)
        
        state.updateZeroFlag(value: state.index_x)
        state.updateNegativeFlag(value: state.index_x)
    }
    
    static func LDY(state: CPUState, addressingMode: AddressingMode) -> Void {
        state.index_y = getOperandByteForAddressingMode(state: state, mode: addressingMode)
        
        state.updateZeroFlag(value: state.index_y)
        state.updateNegativeFlag(value: state.index_y)
    }
    
    //Register instructions
    static func TAX(state: CPUState, addressingMode: AddressingMode) -> Void {
        state.index_x = state.accumulator
        
        state.updateZeroFlag(value: state.index_x);
        state.updateNegativeFlag(value: state.index_x);
    }
    
    static func TXA(state: CPUState, addressingMode: AddressingMode) -> Void {
        state.accumulator = state.index_x
        
        state.updateZeroFlag(value: state.accumulator);
        state.updateNegativeFlag(value: state.accumulator);
    }
    
    static func DEX(state: CPUState, addressingMode: AddressingMode) -> Void {
        state.index_x = state.index_x &- 1
        
        state.updateZeroFlag(value: state.index_x);
        state.updateNegativeFlag(value: state.index_x);
    }
    
    static func INX(state: CPUState, addressingMode: AddressingMode) -> Void {
        state.index_x = state.index_x &+ 1
        
        state.updateZeroFlag(value: state.index_x);
        state.updateNegativeFlag(value: state.index_x);
    }
    
    static func TAY(state: CPUState, addressingMode: AddressingMode) -> Void {
        state.index_y = state.accumulator
        
        state.updateZeroFlag(value: state.index_y);
        state.updateNegativeFlag(value: state.index_y);
    }
    
    static func TYA(state: CPUState, addressingMode: AddressingMode) -> Void {
        state.accumulator = state.index_y
        
        state.updateZeroFlag(value: state.accumulator);
        state.updateNegativeFlag(value: state.accumulator);
    }
    
    static func DEY(state: CPUState, addressingMode: AddressingMode) -> Void {
        state.index_y = state.index_x &- 1
        
        state.updateZeroFlag(value: state.index_y);
        state.updateNegativeFlag(value: state.index_y);
    }
    
    static func INY(state: CPUState, addressingMode: AddressingMode) -> Void {
        state.index_y = state.index_x &+ 1
        
        state.updateZeroFlag(value: state.index_y);
        state.updateNegativeFlag(value: state.index_y);
    }
    
    static func INC(state: CPUState, addressingMode: AddressingMode) -> Void {
        let address: UInt16
        var val: UInt8
        
        if(addressingMode == .zeropage || addressingMode == .zeropage_indexed_x) {
            address = zpAsUInt16(address: state.getOperandByte())
            val = state.memoryInterface.readByte(offset: address)

        }
        else if (addressingMode == .absolute || addressingMode == .absolute_indexed_x) {
            address = state.getOperandWord()
            val = state.memoryInterface.readByte(offset: address)
        }
        else {
            print("Illegal addressing mode for INC")
            return
        }
        
        val = val &+ 1
        state.memoryInterface.writeByte(offset: address, value: val)
            
        state.updateZeroFlag(value: val);
        state.updateNegativeFlag(value: val);
    }
    
    static func DEC(state: CPUState, addressingMode: AddressingMode) -> Void {
        let address: UInt16
        var val: UInt8
        
        if(addressingMode == .zeropage || addressingMode == .zeropage_indexed_x) {
            address = zpAsUInt16(address: state.getOperandByte())
            val = state.memoryInterface.readByte(offset: address)
            
        }
        else if (addressingMode == .absolute || addressingMode == .absolute_indexed_x) {
            address = state.getOperandWord()
            val = state.memoryInterface.readByte(offset: address)
        }
        else {
            print("Illegal addressing mode for INC")
            return
        }
        
        val = val &- 1
        state.memoryInterface.writeByte(offset: address, value: val)
        
        state.updateZeroFlag(value: val);
        state.updateNegativeFlag(value: val);
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
        
        state.updateZeroFlag(value: state.index_x);
        state.updateNegativeFlag(value: state.index_x);
    }
    
    static func PHA(state: CPUState, addressingMode: AddressingMode) -> Void {
        state.memoryInterface.writeByte(offset: stackPointerAsUInt16(state: state), value: state.accumulator)
        state.stack_pointer = state.stack_pointer &- 1
    }
    
    static func PLA(state: CPUState, addressingMode: AddressingMode) -> Void {
        state.stack_pointer = state.stack_pointer &+ 1
        state.accumulator = state.memoryInterface.readByte(offset: stackPointerAsUInt16(state: state))
        
        state.updateZeroFlag(value: state.accumulator);
        state.updateNegativeFlag(value: state.accumulator);
    }
    
    static func PHP(state: CPUState, addressingMode: AddressingMode) -> Void {
        state.memoryInterface.writeByte(offset: stackPointerAsUInt16(state: state), value: state.status_register.asByte())
        state.stack_pointer = state.stack_pointer &- 1
    }
    
    static func PLP(state: CPUState, addressingMode: AddressingMode) -> Void {
        state.stack_pointer = state.stack_pointer &+ 1
        state.status_register.fromByte(state: state.memoryInterface.readByte(offset: stackPointerAsUInt16(state: state)))
    }
    
    //Misc
    static func JMP(state: CPUState, addressingMode: AddressingMode) -> Void {
        state.program_counter = getOperandWordForAddressingMode(state: state, mode: addressingMode)
    }
    
    
    static func NOP(state: CPUState, addressingMode: AddressingMode) -> Void {}
}

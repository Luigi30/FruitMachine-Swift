//
//  Opcodes.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 7/20/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

extension CPU {

    fileprivate func popByte() -> UInt8 {
        stack_pointer = stack_pointer &+ 1
        return memoryInterface.readByte(offset: stackPointerAsUInt16())
    }
    
    fileprivate func popWord() -> UInt16 {
        let low = popByte()
        let high = popByte()
        
        return (UInt16(high) << 8) | UInt16(low)
    }
    
    fileprivate func pushByte(data: UInt8) -> Void {
        memoryInterface.writeByte(offset: stackPointerAsUInt16(), value: data)
        stack_pointer = stack_pointer &- 1
    }

    fileprivate func pushWord(data: UInt16) -> Void {
        let low = UInt8(data & 0x00FF)
        let high = UInt8((data & 0xFF00) >> 8)
        
        pushByte(data: high)
        pushByte(data: low)
    }
 
    fileprivate func stackPointerAsUInt16() -> UInt16 {
        return 0x0100 | UInt16(stack_pointer);
    }
    
    fileprivate func doBranch() {
        let distance = Int8(bitPattern: getOperandByte())
        
        if(distance < 0) {
            if((program_counter & 0x00FF) &- UInt16(abs(Int16(distance))) > 0x8000) {
                page_boundary_crossed = true
            }
        } else {
            if((program_counter & 0x00FF) &+ UInt16(abs(Int16(distance))) > 0x0100) {
                page_boundary_crossed = true
            }
        }

        if(distance > 0) {
            program_counter = UInt16(Int(program_counter) + Int(distance))
        } else {
            program_counter = UInt16(Int(program_counter) + Int(distance))
        }

        branch_was_taken = true
        
        if(distance == -2) {
            print("Infinite loop at $\(program_counter.asHexString()). Halting execution.")
            cyclesInBatch = 0
        }
    }
}

private func getOperandByteForAddressingMode(state: CPU, mode: CPU.AddressingMode) -> UInt8 {
    switch (mode) {
        
    case .immediate:
        return state.getOperandByte()
        
    case .zeropage:
        return state.memoryInterface.readByte(offset: UInt16(0x0000 + state.getOperandByte()))
    case .zeropage_indexed_x:
        return state.memoryInterface.readByte(offset: UInt16(state.getOperandByte() &+ state.index_x) & 0x00FF)
    case .zeropage_indexed_y:
        return state.memoryInterface.readByte(offset: UInt16(state.getOperandByte() &+ state.index_y) & 0x00FF)
        
    case .absolute:
        return state.memoryInterface.readByte(offset: state.getOperandWord())
    case .absolute_indexed_x:
        return state.memoryInterface.readByte(offset: state.getOperandWord() &+ UInt16(state.index_x))
    case .absolute_indexed_y:
        return state.memoryInterface.readByte(offset: state.getOperandWord() &+ UInt16(state.index_y))
        
    case .indexed_indirect:
        return state.memoryInterface.readByte(offset: state.memoryInterface.readWord(offset: UInt16(state.memoryInterface.readByte(offset: UInt16(state.program_counter + 1)) &+ state.index_x)))
    case .indirect_indexed:
        return state.memoryInterface.readByte(offset: state.memoryInterface.readWord(offset: UInt16(state.memoryInterface.readByte(offset: UInt16(state.program_counter + 1)))) &+ UInt16(state.index_y))
    default:
        print("Called getOperand: UInt8 on an instruction that expects a UInt16.")
        return 0
    }
}

private func getOperandAddressForAddressingMode(state: CPU, mode: CPU.AddressingMode) -> UInt16 {
    //Function that will provide a 16-bit operand to instructions.
    //All instructions have 2 data bytes, little-endian.
    
    switch(mode) {
    case .zeropage:
        return UInt16(0x0000 &+ (state.memoryInterface.readByte(offset: state.program_counter &+ 1)))
    case .zeropage_indexed_x:
        return UInt16(0x0000 &+ (state.memoryInterface.readByte(offset: state.program_counter &+ 1) &+ state.index_x))
    case .zeropage_indexed_y:
        return UInt16(0x0000 &+ (state.memoryInterface.readByte(offset: state.program_counter &+ 1) &+ state.index_y))
    case .absolute:
        return state.getOperandWord()
    case .absolute_indexed_x:
        return state.getOperandWord() &+ UInt16(state.index_x)
    case .absolute_indexed_y:
        return state.getOperandWord() &+ UInt16(state.index_y)
    case .indexed_indirect:
        let zp: UInt8 = state.memoryInterface.readByte(offset: UInt16(state.program_counter &+ 1))
        //read from (ZP)
        let pointer: UInt16 = state.memoryInterface.readWord(offset: UInt16(zp &+ state.index_x))
        return pointer
    case .indirect_indexed:
        let zp: UInt8 = state.memoryInterface.readByte(offset: UInt16(state.program_counter &+ 1))
        let pointer: UInt16 = state.memoryInterface.readWord(offset: UInt16(zp)) &+ UInt16(state.index_y)
        return pointer
    case .indirect:
        return state.memoryInterface.readWord(offset: state.getOperandWord())
    default:
        print("Called getOperandAddressForAddressingMode: UInt16 with an invalid addressing mode. Address: \(state.program_counter.asHexString())")
        return 0
    }
}

fileprivate func hex2bcd(hex: UInt8) -> UInt8 {
    var y: UInt8 = (hex / 10) << 4
    y = y | (hex % 10)
    return y
}

/* */

final class Opcodes: NSObject {
    
    static func _Add(state: CPU, operand: UInt8, isSubtract: Bool) {
        var t16: UInt16 = UInt16(state.accumulator) &+ UInt16(operand) + UInt16((state.status_register.carry ? UInt8(1) : UInt8(0)))
        let t8: UInt8 = UInt8(t16 & 0xFF)
        
        //state.status_register.overflow = (state.accumulator & 0x80) != (t8 & 0x80)
        state.status_register.overflow = ((t16 ^ UInt16(state.accumulator)) & (t16 ^ UInt16(operand)) & 0x0080) > UInt16(0)
        state.status_register.zero = (t8 == 0)
        state.status_register.negative = (t8 & 0x80) == 0x80
        
        if(state.status_register.decimal) {
            t16 = UInt16(hex2bcd(hex: state.accumulator) + hex2bcd(hex: operand) + (state.status_register.carry ? UInt8(1) : UInt8(0)))
        } else {
            state.status_register.carry = (t16 & 0xFF00) > 0
        }
        
        state.accumulator = t8
    }
    
    static func ADC(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        _Add(state: state, operand: UInt8(getOperandByteForAddressingMode(state: state, mode: addressingMode)), isSubtract: false)
    }
    
    static func SBC(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        let operand = UInt16(getOperandByteForAddressingMode(state: state, mode: addressingMode))
        
        let carryValue = UInt16(state.status_register.carry ? 0 : 1)
        let t16 = UInt16(state.accumulator) &- operand &- carryValue
        
        state.status_register.overflow = ((UInt16(state.accumulator) ^ operand) & (UInt16(state.accumulator) ^ t16) & 0x80) > 0
        state.status_register.carry = (t16 >> 8) == 0
        state.accumulator = UInt8(t16 & 0xFF)
        state.updateZeroFlag(value: UInt8(t16 & 0xFF))
        state.updateNegativeFlag(value: UInt8(t16 & 0xFF))
    }
    
    static func LDA(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        state.accumulator = getOperandByteForAddressingMode(state: state, mode: addressingMode)
 
        state.updateZeroFlag(value: state.accumulator)
        state.updateNegativeFlag(value: state.accumulator)
    }
    
    static func LDX(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        state.index_x = getOperandByteForAddressingMode(state: state, mode: addressingMode)
        
        state.updateZeroFlag(value: state.index_x)
        state.updateNegativeFlag(value: state.index_x)
    }
    
    static func LDY(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        state.index_y = getOperandByteForAddressingMode(state: state, mode: addressingMode)
        
        state.updateZeroFlag(value: state.index_y)
        state.updateNegativeFlag(value: state.index_y)
    }
    
    static func STA(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        let address: UInt16 = getOperandAddressForAddressingMode(state: state, mode: addressingMode)
        state.memoryInterface.writeByte(offset: address, value: state.accumulator)
    }
    
    static func STX(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        let address: UInt16 = getOperandAddressForAddressingMode(state: state, mode: addressingMode)
        state.memoryInterface.writeByte(offset: address, value: state.index_x)
    }

    static func STY(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        let address: UInt16 = getOperandAddressForAddressingMode(state: state, mode: addressingMode)
        state.memoryInterface.writeByte(offset: address, value: state.index_y)
    }
    
    //Register instructions
    static func TAX(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        state.index_x = state.accumulator
        
        state.updateZeroFlag(value: state.index_x);
        state.updateNegativeFlag(value: state.index_x);
    }
    
    static func TXA(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        state.accumulator = state.index_x
        
        state.updateZeroFlag(value: state.accumulator);
        state.updateNegativeFlag(value: state.accumulator);
    }
    
    static func DEX(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        state.index_x = state.index_x &- 1
        
        state.updateZeroFlag(value: state.index_x);
        state.updateNegativeFlag(value: state.index_x);
    }
    
    static func INX(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        state.index_x = state.index_x &+ 1
        
        state.updateZeroFlag(value: state.index_x);
        state.updateNegativeFlag(value: state.index_x);
    }
    
    static func TAY(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        state.index_y = state.accumulator
        
        state.updateZeroFlag(value: state.index_y);
        state.updateNegativeFlag(value: state.index_y);
    }
    
    static func TYA(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        state.accumulator = state.index_y
        
        state.updateZeroFlag(value: state.accumulator);
        state.updateNegativeFlag(value: state.accumulator);
    }
    
    static func DEY(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        state.index_y = state.index_y &- 1
        
        state.updateZeroFlag(value: state.index_y);
        state.updateNegativeFlag(value: state.index_y);
    }
    
    static func INY(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        state.index_y = state.index_y &+ 1
        
        state.updateZeroFlag(value: state.index_y);
        state.updateNegativeFlag(value: state.index_y);
    }
    
    static func INC(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        let address: UInt16 = getOperandAddressForAddressingMode(state: state, mode: addressingMode)
        var val: UInt8 = state.memoryInterface.readByte(offset: address)

        val = val &+ 1
        state.memoryInterface.writeByte(offset: address, value: val)
            
        state.updateZeroFlag(value: val);
        state.updateNegativeFlag(value: val);
    }
    
    static func DEC(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        let address: UInt16 = getOperandAddressForAddressingMode(state: state, mode: addressingMode)
        var val: UInt8 = state.memoryInterface.readByte(offset: address)
        
        val = val &- 1
        state.memoryInterface.writeByte(offset: address, value: val)
        
        state.updateZeroFlag(value: val);
        state.updateNegativeFlag(value: val);
    }
    
    //CMP
    static func CMP(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        let mem = getOperandByteForAddressingMode(state: state, mode: addressingMode)
        let t = state.accumulator &- mem //CMP is a subtract that doesn't affect memory
        
        state.updateZeroFlag(value: t)
        state.updateNegativeFlag(value: t)
        state.status_register.carry = (state.accumulator >= mem)
    }
    
    static func CPX(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        let mem = getOperandByteForAddressingMode(state: state, mode: addressingMode)
        let t = state.index_x &- mem //CMP is a subtract that doesn't affect memory
        
        state.updateZeroFlag(value: t)
        state.updateNegativeFlag(value: t)
        state.status_register.carry = (state.index_x >= mem)
    }
    
    static func CPY(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        let mem = getOperandByteForAddressingMode(state: state, mode: addressingMode)
        let t = state.index_y &- mem //CMP is a subtract that doesn't affect memory
        
        state.updateZeroFlag(value: t)
        state.updateNegativeFlag(value: t)
        state.status_register.carry = (state.index_y >= mem)
    }
    
    //Boolean operators
    static func EOR(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        state.accumulator = state.accumulator ^ getOperandByteForAddressingMode(state: state, mode: addressingMode)
        
        state.updateZeroFlag(value: state.accumulator)
        state.updateNegativeFlag(value: state.accumulator)
    }
    
    static func AND(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        state.accumulator = state.accumulator & getOperandByteForAddressingMode(state: state, mode: addressingMode)
        
        state.updateZeroFlag(value: state.accumulator)
        state.updateNegativeFlag(value: state.accumulator)
    }
    
    static func ORA(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        state.accumulator = state.accumulator | getOperandByteForAddressingMode(state: state, mode: addressingMode)
        
        state.updateZeroFlag(value: state.accumulator)
        state.updateNegativeFlag(value: state.accumulator)
    }
    
    //Bitwise operators
    static func BIT(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        let operand = getOperandByteForAddressingMode(state: state, mode: addressingMode)
        let data = state.accumulator & operand
        
        state.updateZeroFlag(value: data)
        state.updateNegativeFlag(value: operand)
        state.status_register.overflow = (operand & UInt8(0x40)) == 0x40
    }
    
    static func ASL(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        let operand: UInt8
        
        if(addressingMode == .accumulator) {
            operand = state.accumulator
            state.status_register.carry = ((operand & 0x80) == 0x80)
            state.accumulator = (state.accumulator &<< 1) & 0xFE
            state.updateZeroFlag(value: state.accumulator)
            state.updateNegativeFlag(value: state.accumulator)
        }
        else
        {
            let address = getOperandAddressForAddressingMode(state: state, mode: addressingMode)
            var data = state.memoryInterface.readByte(offset: address)
            state.status_register.carry = (data & 0x80) == 0x80
            data = (data &<< 1) & 0xFE
            state.memoryInterface.writeByte(offset: address, value: data)
            state.updateZeroFlag(value: data)
            state.updateNegativeFlag(value: data)
        }
    }
    
    static func LSR(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        let operand: UInt8
        
        if(addressingMode == .accumulator) {
            operand = state.accumulator
            state.status_register.carry = ((operand & 0x01) == 0x01)
            state.accumulator = (state.accumulator &>> 1) & 0x7F
            
            state.updateZeroFlag(value: state.accumulator)
            state.updateNegativeFlag(value: state.accumulator)
        }
        else
        {
            let address = getOperandAddressForAddressingMode(state: state, mode: addressingMode)
            var data = state.memoryInterface.readByte(offset: address)
            state.status_register.carry = (data & 0x01) == 0x01
            data = (data &>> 1) & 0x7F
            state.memoryInterface.writeByte(offset: address, value: data)
            
            state.updateZeroFlag(value: data)
            state.updateNegativeFlag(value: data)
        }
    }
    
    static func ROL(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        let operand: UInt8
        
        if(addressingMode == .accumulator) {
            operand = state.accumulator
            
            state.accumulator = (state.accumulator &<< 1) & 0xFE
            state.accumulator = state.accumulator | (state.status_register.carry ? 0x01 : 0x00)
            
            state.status_register.carry = ((operand & 0x80) == 0x80)
            state.status_register.zero = state.accumulator == 0 ? true : false
            state.status_register.negative = (state.accumulator & 0x80) == 0x80
        }
        else
        {
            let address = getOperandAddressForAddressingMode(state: state, mode: addressingMode)
            var data = state.memoryInterface.readByte(offset: address)
            let t = (data & 0x80) == 0x80 ? true : false
            
            data = (data &<< 1) & 0xFE
            data = data | (state.status_register.carry ? 0x01 : 0x00)
            state.memoryInterface.writeByte(offset: address, value: data)
            
            state.status_register.carry = t
            state.updateZeroFlag(value: data)
            state.updateNegativeFlag(value: data)
        }
    }
    
    static func ROR(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        let operand: UInt8
        
        if(addressingMode == .accumulator) {
            operand = state.accumulator
            
            state.accumulator = (state.accumulator &>> 1) & 0x7F
            state.accumulator = state.accumulator | (state.status_register.carry ? 0x80 : 0x00)
            
            state.status_register.carry = ((operand & 0x01) == 0x01)
            state.status_register.zero = state.accumulator == 0 ? true : false
            state.status_register.negative = (state.accumulator & 0x80) == 0x80
        }
        else
        {
            let address = getOperandAddressForAddressingMode(state: state, mode: addressingMode)
            var data = state.memoryInterface.readByte(offset: address)
            let t = (data & 0x01) == 0x01 ? true : false
            
            data = (data &>> 1) & 0x7F
            data = data | (state.status_register.carry ? 0x80 : 0x00)
            state.memoryInterface.writeByte(offset: address, value: data)
            
            state.status_register.carry = t
            state.updateZeroFlag(value: data)
            state.updateNegativeFlag(value: data)
        }
    }
    
    //Processor flag instructions
    static func CLC(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        state.status_register.carry = false
    }
    
    static func SEC(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        state.status_register.carry = true
    }
    
    static func CLI(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        state.status_register.irq_disable = false
    }
    
    static func SEI(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        state.status_register.irq_disable = true
    }
    
    static func CLV(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        state.status_register.overflow = false
    }
    
    static func CLD(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        state.status_register.decimal = false
    }
    
    static func SED(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        state.status_register.decimal = true
    }
    
    //Stack instructions
    static func TXS(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        state.stack_pointer = state.index_x
    }
    
    static func TSX(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        state.index_x = state.stack_pointer
        
        state.updateZeroFlag(value: state.index_x);
        state.updateNegativeFlag(value: state.index_x);
    }
    
    static func PHA(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        state.pushByte(data: state.accumulator)
    }
    
    static func PLA(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        state.stack_pointer = state.stack_pointer &+ 1
        state.accumulator = state.memoryInterface.readByte(offset: state.stackPointerAsUInt16())
        
        state.updateZeroFlag(value: state.accumulator);
        state.updateNegativeFlag(value: state.accumulator);
    }
    
    static func PHP(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        var sr = state.status_register
        sr.brk = true //PHP pushes B as true
        
        state.memoryInterface.writeByte(offset: state.stackPointerAsUInt16(), value: sr.asByte())
        state.stack_pointer = state.stack_pointer &- 1
    }
    
    static func PLP(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        state.stack_pointer = state.stack_pointer &+ 1
        state.status_register.fromByte(state: state.memoryInterface.readByte(offset: state.stackPointerAsUInt16()))
        state.status_register.brk = false //PLP sets B to 0
    }
    
    static func BPL(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        if(!state.status_register.negative) {
            state.doBranch()
        }
    }
    
    static func BMI(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        if(state.status_register.negative) {
            state.doBranch()
        }
    }
    
    static func BVC(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        if(!state.status_register.overflow) {
            state.doBranch()
        }
    }
    
    static func BVS(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        if(state.status_register.overflow) {
            state.doBranch()
        }
    }
    
    static func BCC(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        if(!state.status_register.carry) {
            state.doBranch()
        }
    }
    
    static func BCS(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        if(state.status_register.carry) {
            state.doBranch()
        }
    }
    
    static func BNE(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        if(!state.status_register.zero) {
            state.doBranch()
        }
    }
    
    static func BEQ(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        if(state.status_register.zero) {
            state.doBranch()
        }
    }
    
    //Misc
    static func JMP(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        state.program_counter = getOperandAddressForAddressingMode(state: state, mode: addressingMode) &- 3
    }
    
    static func JSR(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        state.pushWord(data: state.program_counter + 2)
        state.program_counter = state.getOperandWord() &- 3
    }
    
    static func RTS(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        state.program_counter = state.popWord()
    }
    
    static func RTI(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        state.status_register.fromByte(state: state.popByte())
        state.program_counter = state.popWord() &- 1
        state.status_register.brk = false //RTI sets B to 0
    }
    
    static func BRK(state: CPU, addressingMode: CPU.AddressingMode) -> Void {
        var sr = state.status_register
        sr.brk = true //BRK pushes B as true
        state.pushWord(data: state.program_counter + 2)
        state.pushByte(data: sr.asByte())
        state.status_register.irq_disable = true //BRK disables interrupts before transferring control
        state.program_counter = state.memoryInterface.readWord(offset: 0xFFFE) &- 1
    }
    
    static func NOP(state: CPU, addressingMode: CPU.AddressingMode) -> Void {}
}

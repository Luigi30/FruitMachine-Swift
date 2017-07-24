//
//  Opcodes.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 7/20/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

extension CPUState {

    func popByte() -> UInt8 {
        stack_pointer = stack_pointer &+ 1
        return memoryInterface.readByte(offset: stackPointerAsUInt16())
    }
    
    func popWord() -> UInt16 {
        let low = popByte()
        let high = popByte()
        
        return (UInt16(high) << 8) | UInt16(low)
    }
    
    func pushByte(data: UInt8) -> Void {
        memoryInterface.writeByte(offset: stackPointerAsUInt16(), value: data)
        stack_pointer = stack_pointer &- 1
    }

    func pushWord(data: UInt16) -> Void {
        let low = UInt8(data & 0x00FF)
        let high = UInt8(data & 0xFF00)
        
        pushByte(data: low)
        pushByte(data: high)
    }
 
    func stackPointerAsUInt16() -> UInt16 {
        return 0x0100 | UInt16(stack_pointer);
    }
    
    func doBranch() {
        let distance = Int8(bitPattern: getOperandByte())
        
        if(distance < 0) {
            if((program_counter & 0x00FF) - UInt16(abs(Int16(distance))) > 0x8000) {
                page_boundary_crossed = true
            }
        } else {
            if((program_counter & 0x00FF) + UInt16(abs(Int16(distance)))ß > 0x0100) {
                page_boundary_crossed = true
            }
        }

        program_counter = UInt16(Int(program_counter) + Int(distance))
        branch_was_taken = true
    }
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
    case .indexed_indirect:
        let zp: UInt8 = state.memoryInterface.readByte(offset: UInt16(state.getOperandByte() + state.index_x))
        //read from (ZP)
        let pointer: UInt16 = state.memoryInterface.readWord(offset: UInt16(zp))
        return state.memoryInterface.readWord(offset: pointer)
    case .indirect_indexed:
        let zp: UInt8 = state.memoryInterface.readByte(offset: UInt16(state.getOperandByte()))
        let pointer: UInt16 = state.memoryInterface.readWord(offset: UInt16(zp)) + UInt16(state.index_y)
        return state.memoryInterface.readWord(offset: pointer)
    default:
        print("Called getOperand: UInt16 on an instruction that expects a UInt8")
        return 0
    }
    
}

func hex2bcd(hex: UInt8) -> UInt8 {
    var y: UInt8 = (hex / 10) << 4
    y = y | (hex % 10)
    return y
}

/* */

class Opcodes: NSObject {
    
    static func ADC(state: CPUState, addressingMode: AddressingMode) -> Void {
        let operand = UInt8(getOperandByteForAddressingMode(state: state, mode: addressingMode))
        
        var t16: UInt16 = UInt16(state.accumulator &+ operand) + UInt16((state.status_register.carry ? UInt8(1) : UInt8(0)))
        let t8: UInt8 = UInt8(t16 & 0xFF)
        
        state.status_register.overflow = (~(state.accumulator ^ operand) & (state.accumulator ^ t8) & 0x80) == 0x80
        state.status_register.zero = (t8 == 0)
        state.status_register.negative = (t8 & 0x80) == 0x80
        
        if(state.status_register.decimal) {
            t16 = UInt16(hex2bcd(hex: state.accumulator) + hex2bcd(hex: operand) + (state.status_register.carry ? UInt8(1) : UInt8(0)))
        } else {
            state.status_register.carry = (t16 > 255)
        }
        
        state.accumulator = (UInt8(t16 & 0xFF))
    }
    
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
    
    static func STA(state: CPUState, addressingMode: AddressingMode) -> Void {
        let address: UInt16
        
        if(addressingMode == .zeropage || addressingMode == .zeropage_indexed_x) {
            address = AddressConversions.zeroPageAsUInt16(address: state.getOperandByte())
            state.memoryInterface.writeByte(offset: address, value: state.accumulator)
            
        }
        else if (addressingMode == .absolute || addressingMode == .absolute_indexed_x || addressingMode == .absolute_indexed_y || addressingMode == .indexed_indirect || addressingMode == .indirect_indexed) {
            address = state.getOperandWord()
            state.memoryInterface.writeByte(offset: address, value: state.accumulator)
        }
        else {
            print("Illegal addressing mode for STA")
            return
        }
    }
    
    static func STX(state: CPUState, addressingMode: AddressingMode) -> Void {
        let address: UInt16
        
        if(addressingMode == .zeropage || addressingMode == .zeropage_indexed_y) {
            address = AddressConversions.zeroPageAsUInt16(address: state.getOperandByte())
            state.memoryInterface.writeByte(offset: address, value: state.index_x)
            
        }
        else if (addressingMode == .absolute) {
            address = state.getOperandWord()
            state.memoryInterface.writeByte(offset: address, value: state.index_x)
        }
        else {
            print("Illegal addressing mode for STX")
            return
        }
    }
    
    static func STY(state: CPUState, addressingMode: AddressingMode) -> Void {
        let address: UInt16
        
        if(addressingMode == .zeropage || addressingMode == .zeropage_indexed_x) {
            address = AddressConversions.zeroPageAsUInt16(address: state.getOperandByte())
            state.memoryInterface.writeByte(offset: address, value: state.index_y)
            
        }
        else if (addressingMode == .absolute) {
            address = state.getOperandWord()
            state.memoryInterface.writeByte(offset: address, value: state.index_y)
        }
        else {
            print("Illegal addressing mode for STY")
            return
        }
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
            address = AddressConversions.zeroPageAsUInt16(address: state.getOperandByte())
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
            address = AddressConversions.zeroPageAsUInt16(address: state.getOperandByte())
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
    
    //CMP
    static func CMP(state: CPUState, addressingMode: AddressingMode) -> Void {
        let data = state.accumulator - state.getOperandByte() //CMP is a subtract that doesn't affect memory
        
        state.updateZeroFlag(value: data)
        state.updateNegativeFlag(value: data)
        state.status_register.carry = (data >= 0)
    }
    
    static func CPX(state: CPUState, addressingMode: AddressingMode) -> Void {
        let data = state.index_x - state.getOperandByte() //CMP is a subtract that doesn't affect memory
        
        state.updateZeroFlag(value: data)
        state.updateNegativeFlag(value: data)
        state.status_register.carry = (data >= 0)
    }
    
    static func CPY(state: CPUState, addressingMode: AddressingMode) -> Void {
        let data = state.index_y - state.getOperandByte() //CMP is a subtract that doesn't affect memory
        
        state.updateZeroFlag(value: data)
        state.updateNegativeFlag(value: data)
        state.status_register.carry = (data >= 0)
    }
    
    //Boolean operators
    static func EOR(state: CPUState, addressingMode: AddressingMode) -> Void {
        state.accumulator = state.accumulator ^ getOperandByteForAddressingMode(state: state, mode: addressingMode)
        
        state.updateZeroFlag(value: state.accumulator)
        state.updateNegativeFlag(value: state.accumulator)
    }
    
    static func AND(state: CPUState, addressingMode: AddressingMode) -> Void {
        state.accumulator = state.accumulator & getOperandByteForAddressingMode(state: state, mode: addressingMode)
        
        state.updateZeroFlag(value: state.accumulator)
        state.updateNegativeFlag(value: state.accumulator)
    }
    
    static func ORA(state: CPUState, addressingMode: AddressingMode) -> Void {
        state.accumulator = state.accumulator | getOperandByteForAddressingMode(state: state, mode: addressingMode)
        
        state.updateZeroFlag(value: state.accumulator)
        state.updateNegativeFlag(value: state.accumulator)
    }
    
    //Bitwise operators
    static func BIT(state: CPUState, addressingMode: AddressingMode) -> Void {
        let operand = getOperandByteForAddressingMode(state: state, mode: addressingMode)
        let data = state.accumulator & operand
        
        state.updateZeroFlag(value: data)
        state.updateNegativeFlag(value: operand)
        state.status_register.overflow = (state.accumulator & UInt8(0x40)) == 0x40
    }
    
    static func ASL(state: CPUState, addressingMode: AddressingMode) -> Void {
        let operand: UInt8
        
        if(addressingMode == .implied) {
            operand = state.accumulator
            state.status_register.carry = ((operand & 0x80) == 0x80)
            state.accumulator = (state.accumulator &<< 1) & 0xFE
            state.updateZeroFlag(value: state.accumulator)
            state.updateNegativeFlag(value: state.accumulator)
        } else {
            let address = getOperandWordForAddressingMode(state: state, mode: addressingMode)
            var data = state.memoryInterface.readByte(offset: address)
            state.status_register.carry = (data & 0x80) == 0x80
            data = (data &<< 1) & 0xFE
            state.memoryInterface.writeByte(offset: address, value: data)
            state.updateZeroFlag(value: data)
            state.updateNegativeFlag(value: data)
        }
    }
    
    static func LSR(state: CPUState, addressingMode: AddressingMode) -> Void {
        let operand: UInt8
        
        if(addressingMode == .implied) {
            operand = state.accumulator
            state.status_register.carry = ((operand & 0x01) == 0x01)
            state.accumulator = (state.accumulator &>> 1) & 0x7F
            state.updateZeroFlag(value: state.accumulator)
            state.status_register.negative = false
        } else {
            let address = getOperandWordForAddressingMode(state: state, mode: addressingMode)
            var data = state.memoryInterface.readByte(offset: address)
            state.status_register.carry = (data & 0x01) == 0x01
            data = (data &>> 1) & 0x7F
            state.memoryInterface.writeByte(offset: address, value: data)
            state.updateZeroFlag(value: data)
            state.updateNegativeFlag(value: data)
        }
    }
    
    static func ROL(state: CPUState, addressingMode: AddressingMode) -> Void {
        let operand: UInt8
        
        if(addressingMode == .implied) {
            operand = state.accumulator
            
            state.accumulator = (state.accumulator &<< 1) & 0xFE
            state.accumulator = state.accumulator | (state.status_register.carry ? 0x01 : 0x00)
            
            state.status_register.carry = ((operand & 0x80) == 0x80)
            state.updateZeroFlag(value: state.accumulator)
            state.status_register.negative = (state.accumulator & 0x80) == 0x80
        } else {
            let address = getOperandWordForAddressingMode(state: state, mode: addressingMode)
            var data = state.memoryInterface.readByte(offset: address)
            
            data = (data &<< 1) & 0xFE
            data = data | (state.status_register.carry ? 0x01 : 0x00)
            state.memoryInterface.writeByte(offset: address, value: data)
            
            state.status_register.carry = (data & 0x80) == 0x80
            state.updateZeroFlag(value: data)
            state.status_register.negative = (data & 0x80) == 0x80
        }
    }
    
    static func ROR(state: CPUState, addressingMode: AddressingMode) -> Void {
        let operand: UInt8
        
        if(addressingMode == .implied) {
            operand = state.accumulator
            
            state.status_register.carry = ((operand & 0x01) == 0x01)
            state.accumulator = (state.accumulator &>> 1) & 0x7F
            state.accumulator = state.accumulator | (state.status_register.carry ? 0x80 : 0x00)
            state.updateZeroFlag(value: state.accumulator)
            state.status_register.negative = (state.accumulator & 0x80) == 0x80
        } else {
            let address = getOperandWordForAddressingMode(state: state, mode: addressingMode)
            var data = state.memoryInterface.readByte(offset: address)
            
            state.status_register.carry = (data & 0x01) == 0x01
            data = (data &>> 1) & 0x7F
            data = data | (state.status_register.carry ? 0x80 : 0x00)
            state.memoryInterface.writeByte(offset: address, value: data)
            state.updateZeroFlag(value: data)
            state.status_register.negative = (data & 0x80) == 0x80
        }
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
        state.memoryInterface.writeByte(offset: state.stackPointerAsUInt16(), value: state.accumulator)
        state.stack_pointer = state.stack_pointer &- 1
    }
    
    static func PLA(state: CPUState, addressingMode: AddressingMode) -> Void {
        state.stack_pointer = state.stack_pointer &+ 1
        state.accumulator = state.memoryInterface.readByte(offset: state.stackPointerAsUInt16())
        
        state.updateZeroFlag(value: state.accumulator);
        state.updateNegativeFlag(value: state.accumulator);
    }
    
    static func PHP(state: CPUState, addressingMode: AddressingMode) -> Void {
        state.memoryInterface.writeByte(offset: state.stackPointerAsUInt16(), value: state.status_register.asByte())
        state.stack_pointer = state.stack_pointer &- 1
    }
    
    static func PLP(state: CPUState, addressingMode: AddressingMode) -> Void {
        state.stack_pointer = state.stack_pointer &+ 1
        state.status_register.fromByte(state: state.memoryInterface.readByte(offset: state.stackPointerAsUInt16()))
    }
    
    static func BPL(state: CPUState, addressingMode: AddressingMode) -> Void {
        if(!state.status_register.negative) {
            state.doBranch()
        }
    }
    
    static func BMI(state: CPUState, addressingMode: AddressingMode) -> Void {
        if(state.status_register.negative) {
            state.doBranch()
        }
    }
    
    static func BVC(state: CPUState, addressingMode: AddressingMode) -> Void {
        if(!state.status_register.overflow) {
            state.doBranch()
        }
    }
    
    static func BVS(state: CPUState, addressingMode: AddressingMode) -> Void {
        if(state.status_register.overflow) {
            state.doBranch()
        }
    }
    
    static func BCC(state: CPUState, addressingMode: AddressingMode) -> Void {
        if(!state.status_register.carry) {
            state.doBranch()
        }
    }
    
    static func BCS(state: CPUState, addressingMode: AddressingMode) -> Void {
        if(state.status_register.carry) {
            state.doBranch()
        }
    }
    
    static func BNE(state: CPUState, addressingMode: AddressingMode) -> Void {
        if(!state.status_register.zero) {
            state.doBranch()
        }
    }
    
    static func BEQ(state: CPUState, addressingMode: AddressingMode) -> Void {
        if(state.status_register.zero) {
            state.doBranch()
        }
    }
    
    //Misc
    static func JMP(state: CPUState, addressingMode: AddressingMode) -> Void {
        state.program_counter = getOperandWordForAddressingMode(state: state, mode: addressingMode)
    }
    
    static func JSR(state: CPUState, addressingMode: AddressingMode) -> Void {
        state.pushWord(data: state.program_counter - 1)
        state.program_counter = state.getOperandWord()
    }
    
    static func RTS(state: CPUState, addressingMode: AddressingMode) -> Void {
        state.program_counter = state.popWord() + 1
    }
    
    static func BRK(state: CPUState, addressingMode: AddressingMode) -> Void {
        state.status_register.brk = true
        state.pushWord(data: state.program_counter)
        state.pushByte(data: state.status_register.asByte())
        state.program_counter = state.memoryInterface.readWord(offset: 0xFFFE)
    }
    
    static func NOP(state: CPUState, addressingMode: AddressingMode) -> Void {}
}

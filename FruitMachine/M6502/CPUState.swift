//
//  CPUState.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 7/19/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

enum CPUExceptions : Error {
    case invalidInstruction
}

struct StatusRegister {
    var negative: Bool      //N - 0x80
    var overflow: Bool      //V - 0x40
    //                          - 0x20
    var brk: Bool           //B - 0x10
    var decimal: Bool       //D - 0x08
    var irq_disable: Bool   //I - 0x04
    var zero: Bool          //Z - 0x02
    var carry: Bool         //C - 0x01
    
    mutating func fromByte(state: UInt8) {
        negative    = (state & 0x80 == 0x80)
        overflow    = (state & 0x40 == 0x40)
        brk         = (state & 0x10 == 0x10)
        decimal     = (state & 0x08 == 0x08)
        irq_disable = (state & 0x04 == 0x04)
        zero        = (state & 0x02 == 0x02)
        carry       = (state & 0x01 == 0x01)
    }
    
    func asByte() -> UInt8 {
        var val: UInt8 = 0x00
        
        if(negative) {
            val |= 0x80
        }
        if(overflow) {
            val |= 0x40
        }
        if(brk) {
            val |= 0x10
        }
        if(decimal) {
            val |= 0x08
        }
        if(irq_disable) {
            val |= 0x04
        }
        if(zero) {
            val |= 0x02
        }
        if(carry) {
            val |= 0x01
        }
        
        return val
    }
}

class CPUState: NSObject {
    static var sharedInstance = CPUState()
    
    var cycles: Int
    
    var instruction_register: UInt8
    
    var accumulator: UInt8
    var index_x: UInt8
    var index_y: UInt8
    var stack_pointer: UInt8
    var program_counter: UInt16
    var status_register: StatusRegister
    
    var page_boundary_crossed: Bool
    
    var memoryInterface: MemoryInterface
    
    override init() {
        cycles = 0
        
        instruction_register = 0
        
        accumulator = 0
        index_x = 0
        index_y = 0
        stack_pointer = 0
        program_counter = 0
        status_register = StatusRegister(negative: false, overflow: false, brk: false, decimal: false, irq_disable: false, zero: false, carry: false)
        memoryInterface = MemoryInterface()
        
        page_boundary_crossed = false
    }
    
    func disassemble(fromAddress: UInt16, length: UInt16) -> [Disassembly] {
        var disassembly: [Disassembly] = [Disassembly]()
        
        var currentAddress: UInt16 = fromAddress
        let endAddress: UInt16 = fromAddress + length
        
        while(currentAddress < endAddress) {
            let instruction = memoryInterface.readByte(offset: currentAddress)
            let operation = InstructionTable[instruction]
            var data = [UInt8]()
            
            if(operation != nil) {
                for index in 1...operation!.bytes {
                    data.append(memoryInterface.readByte(offset:currentAddress + UInt16(index)))
                }
                
                disassembly.append(Disassembly(instruction: operation, address: currentAddress, data: data))
                currentAddress = currentAddress + UInt16(operation!.bytes)
            } else {
                currentAddress = currentAddress + 1
            }
        }
        
        return disassembly
    }
    
    func getOperandByte() -> UInt8 {
        //Returns the operand byte after the current instruction byte.
        return memoryInterface.readByte(offset: program_counter + 1)
    }
    
    func getOperandWord() -> UInt16 {
        var word: UInt16
        let low = memoryInterface.readByte(offset: program_counter + 1)
        let high = memoryInterface.readByte(offset: program_counter + 2)
        
        word = UInt16(high)
        word = word << 8
        word |= UInt16(low)
        
        return word
    }
    
    func getInstructionBytes(atAddress: UInt16) -> [UInt8] {
        var bytes = [UInt8]()
        
        let instruction = memoryInterface.readByte(offset: atAddress)
        let operation = InstructionTable[instruction]
        
        if(operation != nil){
            for offset in 0...operation!.bytes {
                bytes.append(memoryInterface.readByte(offset: atAddress + UInt16(offset)))
            }
        }
        
        return bytes
        
    }
        
    func executeNextInstruction() throws {
        instruction_register = memoryInterface.readByte(offset: program_counter)
        let operation = InstructionTable[instruction_register]
        if(operation == nil) {
            throw CPUExceptions.invalidInstruction
        }
        
        operation!.action(CPUState.sharedInstance, operation!.addressingMode)
        
        self.cycles += operation!.cycles
        if(self.page_boundary_crossed) {
            self.cycles += 1
            self.page_boundary_crossed = false
        }
        
        if(operation!.mnemonic != "JMP") {
            self.program_counter = UInt16(Int(self.program_counter) + operation!.bytes)
        }
    }
    
    func updateNegativeFlag(value: UInt8) {
        status_register.negative = (value & 0x80 == 0x80)
    }
    
    func updateZeroFlag(value: UInt8) {
        status_register.zero = (value == 0)
    }
    
}

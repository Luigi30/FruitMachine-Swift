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

enum CPUModel {
    case M6502
    case M65C02
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
    
    func asString() -> String {
        var str = ""
        
        if(negative) {
            str += "N"
        } else {
            str += "-"
        }
        
        if(overflow) {
            str += "V"
        } else {
            str += "-"
        }
        
        str += "|" //0x20 is unassigned
        
        if(brk) {
            str += "B"
        } else {
            str += "-"
        }
        
        if(decimal) {
            str += "D"
        } else {
            str += "-"
        }
        
        if(irq_disable) {
            str += "I"
        } else {
            str += "-"
        }
        
        if(zero) {
            str += "Z"
        } else {
            str += "-"
        }
        
        if(carry) {
            str += "C"
        } else {
            str += "-"
        }
        
        return str
    }
    
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
        var val: UInt8 = 0x20 //unused bit is hardwired to 1
        
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

final class CPU: NSObject {
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
    
    let NMI_VECTOR: UInt16      = 0xFFFA
    let RESET_VECTOR: UInt16    = 0xFFFC
    let IRQ_VECTOR: UInt16      = 0xFFFE
    
    static let sharedInstance = CPU(cpuModel: .M6502)
    
    var isRunning: Bool
    
    var cycles: Int
    var cyclesInBatch: Int
    
    var instruction_register: UInt8
    
    var accumulator: UInt8
    var index_x: UInt8
    var index_y: UInt8
    var stack_pointer: UInt8
    var program_counter: UInt16
    var status_register: StatusRegister
    
    //Debugging
    var old_program_counter: UInt16
    
    var page_boundary_crossed: Bool
    var branch_was_taken: Bool
    
    var memoryInterface: MemoryInterface
    
    var breakpoints: [UInt16]
    
    var model: CPUModel
    
    init(cpuModel: CPUModel) {
        isRunning = false
        
        model = cpuModel
        
        cycles = 0
        cyclesInBatch = 0
        
        instruction_register = 0
        
        accumulator = 0
        index_x = 0
        index_y = 0
        stack_pointer = 0
        program_counter = 0
        old_program_counter = 0
        status_register = StatusRegister(negative: false, overflow: false, brk: false, decimal: false, irq_disable: false, zero: false, carry: false)
        memoryInterface = MemoryInterface()
        
        //Some instructions incur a 1-cycle penalty if crossing a page boundary.
        page_boundary_crossed = false
        //Branches incur a 1-cycle penalty if taken plus the page boundary penalty if necessary.
        branch_was_taken = false
        
        breakpoints = [UInt16]()
    }
    
    func coldReset() {
        instruction_register = 0
        
        accumulator = 0
        index_x = 0
        index_y = 0
        stack_pointer = 0
        program_counter = 0
        status_register = StatusRegister(negative: false, overflow: false, brk: false, decimal: false, irq_disable: false, zero: false, carry: false)
        
        //Some instructions incur a 1-cycle penalty if crossing a page boundary.
        page_boundary_crossed = false
        //Branches incur a 1-cycle penalty if taken plus the page boundary penalty if necessary.
        branch_was_taken = false
        
        performReset()
        
        for address in 0 ..< 0xC000 {
            memoryInterface.writeByte(offset: UInt16(address), value: 0x00, bypassOverrides: true)
        }
    }
    
    func changeModel(cpuModel: CPUModel) {
        model = cpuModel
        coldReset()
    }
    
    func getOperandByte() -> UInt8 {
        //Returns the operand byte after the current instruction byte.
        return memoryInterface.readByte(offset: program_counter &+ 1)
    }
    
    func getOperandWord() -> UInt16 {
        var word: UInt16
        let low = memoryInterface.readByte(offset: program_counter &+ 1)
        let high = memoryInterface.readByte(offset: program_counter &+ 2)
        
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
        
    final func executeNextInstruction() throws {
        instruction_register = memoryInterface.readByte(offset: program_counter)
        let operation = InstructionTable[instruction_register]
        if(operation == nil) {
            throw CPUExceptions.invalidInstruction
        }
        
        if(program_counter == 0x102F) {
            print("$102F")
        }
        
        self.old_program_counter = self.program_counter
        operation!.action(CPU.sharedInstance, operation!.addressingMode)
        
        self.cycles += operation!.cycles
        if(self.page_boundary_crossed) {
            self.cycles += 1
            self.page_boundary_crossed = false
        }
        if(self.branch_was_taken) {
            self.cycles += 1
            self.branch_was_taken = false
        }
        
        
        self.program_counter = Address(self.program_counter &+ UInt16(operation!.bytes))
    }
    
    func outOfCycles() -> Bool {
        if(cycles > cyclesInBatch) {
            return true
        } else {
            return false
        }
    }
    
    func performReset() {
        program_counter = memoryInterface.readWord(offset: RESET_VECTOR)
        stack_pointer = 0xFF
        status_register.irq_disable = true
    }
    
    func updateNegativeFlag(value: UInt8) {
        status_register.negative = (value & 0x80 == 0x80)
    }
    
    func updateZeroFlag(value: UInt8) {
        status_register.zero = (value == 0)
    }
    
    /* Running */
    final func cpuStep() {
        do {
            try executeNextInstruction()
        } catch CPUExceptions.invalidInstruction {
            print("Invalid instruction at \(program_counter.asHexString())")
            coldReset()
        } catch {
            print(error)
        }
    }
    
    func runCyclesBatch() {
        isRunning = true
        
        while(!outOfCycles()) {
            cpuStep()
            
            if (breakpoints.contains(program_counter)) {
                isRunning = false
            }
            
        }
    }
    
}

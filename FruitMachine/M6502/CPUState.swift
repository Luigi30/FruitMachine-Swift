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
    
    mutating func setState(state: UInt8) {
        negative    = (state & 0x80 == 0x80)
        overflow    = (state & 0x40 == 0x40)
        brk         = (state & 0x10 == 0x10)
        decimal     = (state & 0x08 == 0x08)
        irq_disable = (state & 0x04 == 0x04)
        zero        = (state & 0x02 == 0x02)
        carry       = (state & 0x01 == 0x01)
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
    
    func executeNextInstruction() throws {
        instruction_register = memoryInterface.memory[Int(program_counter)]
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
    }
    
    func setNegativeFlag() {
        status_register.negative = (accumulator & 0x80 == 0x80)
    }
    
    func setZeroFlag() {
        status_register.zero = (accumulator == 0)
    }
}

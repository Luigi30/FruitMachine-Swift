//
//  DosFormat.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 8/3/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

protocol DiskImageFormat {
    static var BYTES_PER_SECTOR: Int { get }
    static var SECTORS_PER_TRACK: Int { get }
    static var TRACKS_PER_DISK: Int { get }
    static var BYTES_PER_TRACK: Int { get }
}

class Dos33Image: DiskImageFormat {
    static let BYTES_PER_SECTOR: Int = 256
    static let SECTORS_PER_TRACK: Int = 16
    static let TRACKS_PER_DISK: Int = 35
    static let BYTES_PER_TRACK: Int = BYTES_PER_SECTOR * SECTORS_PER_TRACK
    
    //Sectors in a track are in this order.
    //                        0  7  14  6  13  5  12  4  11  3  10  2  9  1  8  15
    static let sectorOrder = [0, 7, 14, 6, 13, 5, 12, 4, 11, 3, 10, 2, 9, 1, 8, 15]
    
    struct VTOC {
        //http://fileformats.archiveteam.org/wiki/Apple_DOS_file_system
        
                                    //$00 unused
        let catalogTrackNumber = 0  //$01
        let catalogSectorNumber = 0 //$02
        let dosInitVersion = 0      //$03
                                    //$04-05 unused
        let volumeNumber = 0        //$06
                                    //$07-$26 unused
        let maxTrackSectorPairs = 0 //$27, should be 122
                                    //$28-$2F unused
        let lastFormattedTrack = 0  //$30
        let trackDirection = 0      //$31
                                    //$32-$33 unused
        let tracksPerDisk = 0       //$34
        let sectorsPerTrack = 0     //$35
        let bytesPerSector = 0      //$36-$37
    }
    
    let tableOfContents = VTOC()
    
    static func readTrackAndSector(imageData: [UInt8], trackNum: Int, sectorNum: Int) -> [UInt8] {
        //Find the track in our disk.
        let trackOffset = trackNum * Dos33Image.BYTES_PER_TRACK
        //Find the sector in this track.
        let sectorOffset = sectorOrder[sectorNum] * Dos33Image.BYTES_PER_SECTOR
        let offset = trackOffset + sectorOffset
        
        return Array<UInt8>(imageData[offset ..< offset + Dos33Image.BYTES_PER_SECTOR])
    }
}

class DiskImage: NSObject {
    enum DiskFormat {
        case Dos33
        case Prodos
        case Raw
    }
    	
    var encodedTracks = [[UInt8]]()
    var fileSize: UInt64 = 0
    var image: DiskImageFormat?
    
    init(diskPath: String) {
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: diskPath)
            fileSize = attr[FileAttributeKey.size] as! UInt64
        } catch {
            print("Error in DiskImage: \(error)")
        }
        
        super.init()
        var rawData: [UInt8]?
        
        rawData = loadImageBytes(path: diskPath, size: Int(fileSize))
        if(rawData == nil) {
            print("Couldn't load disk image")
            return
        }
        //Is this a DOS 3.3 format image? Read one sector from track $11.
        let catalogSector: [UInt8] = Dos33Image.readTrackAndSector(imageData: rawData!, trackNum: 0x11, sectorNum: 0)
        
        for track in 0..<Dos33Image.TRACKS_PER_DISK {
            encodedTracks.append(encodeDos33Track(imageData: rawData!, index: track, volumeNumber: Int(catalogSector[0x06])))
        }
        
        let pointer = UnsafeBufferPointer(start:encodedTracks[2], count:encodedTracks[2].count)
        let data = Data(buffer:pointer)
        try! data.write(to: URL(fileURLWithPath: "/Users/luigi/apple2/master.dmp"))
    }
    
    private func loadImageBytes(path: String, size: Int) -> [UInt8]? {
        do {
            var data = [UInt8](repeating: 0xCC, count: Int(fileSize))
            
            let fileContent: NSData = try NSData(contentsOfFile: path)
            fileContent.getBytes(&data, range: NSRange(location: 0, length: Int(size)))
            
            return data
        } catch {
            print(error)
        }
        
        return nil
    }
    
    private func encodeDos33Track(imageData: [UInt8], index: Int, volumeNumber: Int) -> [UInt8] {
        var encodedData = [UInt8]()
        let dataOffset = index * Dos33Image.BYTES_PER_TRACK
        
        //Prologue: add 48 self-syncing bytes
        for _ in 1..<0x30 { encodedData.append(selfSync) }
        
        for sectorNum in 0 ..< Dos33Image.SECTORS_PER_TRACK {
            //Address Field
            encodedData.append(contentsOf: addressPrologue)
            encodedData.append(contentsOf: UInt16toUInt8Array(word: FourAndFourEncode(byte: UInt8(volumeNumber))))    //Volume byte
            encodedData.append(contentsOf: UInt16toUInt8Array(word: FourAndFourEncode(byte: UInt8(index))))           //Track number
            encodedData.append(contentsOf: UInt16toUInt8Array(word: FourAndFourEncode(byte: UInt8(sectorNum))))       //Sector number
            let checksum: UInt8 = UInt8(volumeNumber) ^ UInt8(index) ^ UInt8(sectorNum)
            encodedData.append(contentsOf: UInt16toUInt8Array(word: FourAndFourEncode(byte: UInt8(checksum))))        //Checksum value
            encodedData.append(contentsOf: addressEpilogue)
            
            //Gap2 - 5 bytes
            for _ in 0..<6 { encodedData.append(selfSync) }
            
            //Data Field
            encodedData.append(contentsOf: dataPrologue)
            encodedData.append(contentsOf: EncodeSectorSixAndTwo(sector: Dos33Image.readTrackAndSector(imageData: imageData, trackNum: index, sectorNum: sectorNum)))
            encodedData.append(contentsOf: dataEpilogue)
            
            //Gap2
            for _ in 0..<20 { encodedData.append(selfSync) }
        }
        
        return encodedData
    }
    
    private func UInt16toUInt8Array(word: UInt16) -> [UInt8] {
        var r = [UInt8]()
        r.append(UInt8((word & 0xFF00) >> 8))
        r.append(UInt8(word & 0x00FF))
        
        return r
    }
    
    private func EncodeSectorSixAndTwo(sector: [UInt8]) -> [UInt8] {
        let encodedBuffer = SixAndTwoPrenibblize(sector: sector)
        var writtenData = [UInt8](repeating: 0x00, count: 343)
        
        //We have a prepared buffer.
        writtenData[0] = SixAndTwoTranslationTable[Int(0 ^ encodedBuffer[0x155])]
        writtenData[86] = SixAndTwoTranslationTable[Int(encodedBuffer[0x100] ^ encodedBuffer[0x00])]
        
        for index in 0x00 ... 0xFE {
            writtenData[87 + index] = SixAndTwoTranslationTable[Int(encodedBuffer[index] ^ encodedBuffer[index + 1])]
        }
        
        for (i, index) in (0x100 ... 0x154).enumerated() {
            writtenData[85-i] = SixAndTwoTranslationTable[Int(encodedBuffer[index] ^ encodedBuffer[index + 1])]
        }
        
        writtenData[342] = SixAndTwoTranslationTable[Int(encodedBuffer[0xFF])]
        
        return writtenData
    }
    
    private func SixAndTwoPrenibblize(sector: [UInt8]) -> [UInt8] {
        //Create a 342-byte buffer from a 256-byte sector.
        var nibblized: [UInt8] = [UInt8](repeating: 0x00, count: 342)
        
        for byte in 0x00...0x55 {
            nibblized[byte] = sector[byte] >> 2
            let b0 = (sector[byte] & 0b00000001)
            let b1 = (sector[byte] & 0b00000010)
            let low = 0x00 | (b0 << 1 | b1 >> 1)
            
            nibblized[0x155 - byte] |= low
        }
        
        for byte in 0x56...0xAA {
            nibblized[byte] = sector[byte] >> 2
            let b0 = (sector[byte] & 0b00000001)
            let b1 = (sector[byte] & 0b00000010)
            let low = (b0 << 1 | b1 >> 1)
            
            nibblized[0x155 - (byte % 0x56)] |= (low << 2)
        }
        
        for byte in 0xAB...0xFF {
            nibblized[byte] = sector[byte] >> 2
            let b0 = (sector[byte] & 0b00000001)
            let b1 = (sector[byte] & 0b00000010)
            let low = (b0 << 1 | b1 >> 1)
            
            //Now we have a full six bits.
            let completeLow: UInt8 = nibblized[0x155 - (byte % 0x56)] | (low << 4)
            nibblized[0x155 - (byte % 0x56)] = completeLow
        }
        
        return nibblized
    }
    
    //Convert bytes to the different encoding schemes.
    private func FourAndFourEncode(byte: UInt8) -> UInt16 {
    /*
         4 and 4 encoded bytes require two bytes (by splitting actual bits
         evenly between two bytes) and have the following format:
     
         1  b7  1  b5  1  b3  1  b1
         1  b6  1  b4  1  b2  1  b0
     */
        var encoded: UInt16 = 0
        
        let hi: UInt16 = UInt16((byte >> 1) | 0b10101010)
        let lo: UInt16 = UInt16(byte | 0b10101010)
        
        encoded = (hi << 8) | lo
        return encoded
    }
    
    func SixAndTwoEncode(byte: UInt8) -> UInt8 {
        return SixAndTwoTranslationTable[Int(byte)]
    }
    
    //A group of self-syncing bytes. This pattern can be repeated as long as required.
    //let selfSyncFive: [UInt8] = [0b11111111, 0b00111111, 0b11001111, 0b11110011, 0b11111100]
    private let selfSync: UInt8 = 0xFF
    
    private let addressPrologue: [UInt8] = [0xD5, 0xAA, 0x96]
    private let addressEpilogue: [UInt8] = [0xDE, 0xAA, 0xEB]
    
    private let dataPrologue: [UInt8] = [0xD5, 0xAA, 0xAD]
    private let dataEpilogue: [UInt8] = [0xDE, 0xAA, 0xEB]
    
    private let SixAndTwoTranslationTable: [UInt8] = [0x96, 0x97, 0x9A, 0x9B, 0x9D, 0x9E, 0x9F, 0xA6,
                                              0xA7, 0xab, 0xac, 0xad, 0xae, 0xaf, 0xb2, 0xb3,
                                              0xb4, 0xb5, 0xb6, 0xb7, 0xb9, 0xba, 0xbb, 0xbc,
                                              0xbd, 0xbe, 0xbf, 0xcb, 0xcd, 0xce, 0xcf, 0xd3,
                                              0xd6, 0xd7, 0xd9, 0xda, 0xdb, 0xdc, 0xdd, 0xde,
                                              0xdf, 0xe5, 0xe6, 0xe7, 0xe9, 0xea, 0xeb, 0xec,
                                              0xed, 0xee, 0xef, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6,
                                              0xf7, 0xf9, 0xfa, 0xfb, 0xfc, 0xfd, 0xfe, 0xff]
}

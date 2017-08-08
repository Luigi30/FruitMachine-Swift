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
    
    static var SECTOR_ORDER: [Int] { get }
}

enum DiskFormat {
    case Dos33
    case Prodos
    case Raw
}

class Dos33Image: DiskImageFormat {
    static let BYTES_PER_SECTOR: Int = 256
    static let SECTORS_PER_TRACK: Int = 16
    static let TRACKS_PER_DISK: Int = 35
    static let BYTES_PER_TRACK: Int = BYTES_PER_SECTOR * SECTORS_PER_TRACK
    
    //Sectors in a track are in this order.
    static let SECTOR_ORDER = [0, 7, 14, 6, 13, 5, 12, 4, 11, 3, 10, 2, 9, 1, 8, 15]
    
    static func readTrackAndSector(imageData: [UInt8], trackNum: Int, sectorNum: Int) -> [UInt8] {
        //Find the track in our disk.
        let trackOffset = trackNum * Dos33Image.BYTES_PER_TRACK
        //Find the sector in this track.
        let sectorOffset = SECTOR_ORDER[sectorNum] * BYTES_PER_SECTOR
        let offset = trackOffset + sectorOffset
        
        return Array<UInt8>(imageData[offset ..< offset + BYTES_PER_SECTOR])
    }
}

class ProdosImage: DiskImageFormat {
    static let BYTES_PER_SECTOR: Int = 256
    static let SECTORS_PER_TRACK: Int = 16
    static let TRACKS_PER_DISK: Int = 35
    static let BYTES_PER_TRACK: Int = BYTES_PER_SECTOR * SECTORS_PER_TRACK
    
    //Sectors in a track are in this order.
    static let SECTOR_ORDER = [0, 8, 1, 9, 2, 10, 3, 11, 4, 12, 5, 13, 6, 14, 7, 15]
    //static let SECTOR_ORDER = [0, 7, 14, 6, 13, 5, 12, 4, 11, 3, 10, 2, 9, 1, 8, 15]
    
    static func readTrackAndSector(imageData: [UInt8], trackNum: Int, sectorNum: Int) -> [UInt8] {
        //Find the track in our disk.
        let trackOffset = trackNum * ProdosImage.BYTES_PER_TRACK
        //Find the sector in this track.
        let sectorOffset = sectorNum * BYTES_PER_SECTOR
        let offset = trackOffset + sectorOffset
        
        return Array<UInt8>(imageData[offset ..< offset + BYTES_PER_SECTOR])
    }
    
    static func readBlock(imageData: [UInt8], blockNum: Int) -> [UInt8] {
        var blockData = [UInt8]()
        
        /* Find the track number. */
        let track = blockNum / 8
        
        /* Find the sector numbers. */
        let blockOffset8 = blockNum % 8
        var sector1 = 0
        var sector2 = 0
        
        switch blockOffset8 {
        case 0:
            sector1 = 0
            sector2 = 0xE
        case 1:
            sector1 = 0xD
            sector2 = 0xC
        case 2:
            sector1 = 0xB
            sector2 = 0xA
        case 3:
            sector1 = 0x9
            sector2 = 0x8
            
        case 4:
            sector1 = 0x7
            sector2 = 0x6
        case 5:
            sector1 = 0x5
            sector2 = 0x4
        case 6:
            sector1 = 0x3
            sector2 = 0x2
        case 7:
            sector1 = 0x1
            sector2 = 0xF
        default:
            print("should never happen")
        }
        
        blockData.append(contentsOf: [UInt8](readTrackAndSector(imageData: imageData, trackNum: track, sectorNum: sector1)))
        blockData.append(contentsOf: [UInt8](readTrackAndSector(imageData: imageData, trackNum: track, sectorNum: sector2)))
        
        return blockData
    }
}

class DiskImage: NSObject {
    	
    var encodedTracks = [[UInt8]]()
    var fileSize: UInt64 = 0
    var image: DiskImageFormat?
    var writeProtect = false
    
    var filename: String
    
    init(diskPath: String) {
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: diskPath)
            fileSize = attr[FileAttributeKey.size] as! UInt64
        } catch {
            print("Error in DiskImage: \(error)")
        }
        
        filename = diskPath
        
        super.init()
        var rawData: [UInt8]?
        
        rawData = loadImageBytes(path: diskPath, size: Int(fileSize))
        if(rawData == nil) {
            print("Couldn't load disk image")
            return
        }
        if(filename.contains(".do")) {
            //Is this a DOS 3.3 format image? Read one sector from track $11.
            image = Dos33Image()
            let catalogSector: [UInt8] = Dos33Image.readTrackAndSector(imageData: rawData!, trackNum: 0x11, sectorNum: 0)
            for track in 0..<Dos33Image.TRACKS_PER_DISK {
                encodedTracks.append(encodeTrack(imageData: rawData!, index: track, volumeNumber: Int(catalogSector[0x06])))
            }

        } else if(filename.contains(".po")) {
            /* ProDOS-order image. */
            image = ProdosImage()
            
            for track in 0..<ProdosImage.TRACKS_PER_DISK {
                encodedTracks.append(encodeTrack(imageData: rawData!, index: track, volumeNumber: 0xFE))
            }
            
            var blks = [UInt8]()
            var nbls = [UInt8]()
            
            for track in encodedTracks {
                nbls.append(contentsOf: track)
            }
 
            blks.append(contentsOf: ProdosImage.readBlock(imageData: rawData!, blockNum: 7))
        
            var ptr = UnsafeBufferPointer(start: blks, count: blks.count)
            var data = Data(buffer: ptr)
            try! data.write(to: URL(fileURLWithPath: filename + ".blk"))
            
            ptr = UnsafeBufferPointer(start: nbls, count: nbls.count)
            data = Data(buffer: ptr)
            try! data.write(to: URL(fileURLWithPath: filename + ".nbl"))
            
        } else {
            /* TODO: Hook up logic to figure out the disk format. */
            image = Dos33Image()
        }

    }
    
    func saveDiskImage() {
        var diskBytes = [UInt8]()
        
        for track in 0 ..< Dos33Image.TRACKS_PER_DISK {
            diskBytes.append(contentsOf: decodeTrack(index: track))
        }
        
        let ptr = UnsafeBufferPointer(start: diskBytes, count: diskBytes.count)
        let data = Data(buffer: ptr)
        try! data.write(to: URL(fileURLWithPath: filename))
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
    
    private func decodeTrack(index: Int) -> [UInt8] {
        /* Find the first sector. Each sector starts with $D5 $AA $AD */
        let track = encodedTracks[index]
        var trackBytes = [UInt8]()
        
        if(image is Dos33Image) {
            for i in 0 ..< Dos33Image.SECTORS_PER_TRACK {
                let sectorOffset: Int = 0x47 + (0x18C * Dos33Image.SECTOR_ORDER.index(of: i)!)
                let nibbles: [UInt8] = [UInt8](track[sectorOffset ... sectorOffset + 343])
                trackBytes.append(contentsOf: DecodeSectorSixAndTwo(nibbles: nibbles))
            }
        } else if(image is ProdosImage) {
            for i in 0 ..< ProdosImage.SECTORS_PER_TRACK {
                let sectorOffset: Int = 0x47 + (0x18C * ProdosImage.SECTOR_ORDER.index(of: i)!)
                let nibbles: [UInt8] = [UInt8](track[sectorOffset ... sectorOffset + 343])
                trackBytes.append(contentsOf: DecodeSectorSixAndTwo(nibbles: nibbles))
            }
        } else if(image != nil) {
            for i in 0 ..< Dos33Image.SECTORS_PER_TRACK {
                let sectorOffset: Int = 0x47 + (0x18C * i) /* If we don't recognize the format, just use a sequential sector order. */
                let nibbles: [UInt8] = [UInt8](track[sectorOffset ... sectorOffset + 343])
                trackBytes.append(contentsOf: DecodeSectorSixAndTwo(nibbles: nibbles))
            }
        }
        
        return trackBytes
    }
    
    private func encodeTrack(imageData: [UInt8], index: Int, volumeNumber: Int) -> [UInt8] {
        var encodedData = [UInt8]()
        
        //Prologue: add 48 self-syncing bytes
        for _ in 1..<0x31 { encodedData.append(selfSync) }
        
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
            //343 bytes: 342-byte sector + 1-byte checksum
            if(image is Dos33Image) {
                encodedData.append(contentsOf: EncodeSectorSixAndTwo(sector: Dos33Image.readTrackAndSector(imageData: imageData, trackNum: index, sectorNum: sectorNum)))
            }
            else if(image is ProdosImage){
                /* TODO: A .PO image is stored by 512-blocks which are not contiguous on the disk. Need to adapt this to handle blocks. */
                
                /* Find the 256 bytes corresponding to this sector. */
                switch(sectorNum)
                {
                case 0x00:
                    let block = ProdosImage.readBlock(imageData: imageData, blockNum: (8 * index) + 0)
                    encodedData.append(contentsOf: EncodeSectorSixAndTwo(sector: [UInt8](block[0x000...0x0FF])))
                case 1:
                    let block = ProdosImage.readBlock(imageData: imageData, blockNum: (8 * index) + 4)
                    encodedData.append(contentsOf: EncodeSectorSixAndTwo(sector: [UInt8](block[0x000...0x0FF])))
                case 0x02:
                    let block = ProdosImage.readBlock(imageData: imageData, blockNum: (8 * index) + 0)
                    encodedData.append(contentsOf: EncodeSectorSixAndTwo(sector: [UInt8](block[0x100...0x1FF])))
                case 3:
                    let block = ProdosImage.readBlock(imageData: imageData, blockNum: (8 * index) + 4)
                    encodedData.append(contentsOf: EncodeSectorSixAndTwo(sector: [UInt8](block[0x100...0x1FF])))
                case 4:
                    let block = ProdosImage.readBlock(imageData: imageData, blockNum: (8 * index) + 1)
                    encodedData.append(contentsOf: EncodeSectorSixAndTwo(sector: [UInt8](block[0x000...0x0FF])))
                case 5:
                    let block = ProdosImage.readBlock(imageData: imageData, blockNum: (8 * index) + 5)
                    encodedData.append(contentsOf: EncodeSectorSixAndTwo(sector: [UInt8](block[0x000...0x0FF])))
                case 6:
                    let block = ProdosImage.readBlock(imageData: imageData, blockNum: (8 * index) + 1)
                    encodedData.append(contentsOf: EncodeSectorSixAndTwo(sector: [UInt8](block[0x100...0x1FF])))
                case 7:
                    let block = ProdosImage.readBlock(imageData: imageData, blockNum: (8 * index) + 5)
                    encodedData.append(contentsOf: EncodeSectorSixAndTwo(sector: [UInt8](block[0x100...0x1FF])))
                case 8:
                    let block = ProdosImage.readBlock(imageData: imageData, blockNum: (8 * index) + 2)
                    encodedData.append(contentsOf: EncodeSectorSixAndTwo(sector: [UInt8](block[0x000...0x0FF])))
                case 9:
                    let block = ProdosImage.readBlock(imageData: imageData, blockNum: (8 * index) + 6)
                    encodedData.append(contentsOf: EncodeSectorSixAndTwo(sector: [UInt8](block[0x000...0x0FF])))
                case 10:
                    let block = ProdosImage.readBlock(imageData: imageData, blockNum: (8 * index) + 2)
                    encodedData.append(contentsOf: EncodeSectorSixAndTwo(sector: [UInt8](block[0x100...0x1FF])))
                case 11:
                    let block = ProdosImage.readBlock(imageData: imageData, blockNum: (8 * index) + 6)
                    encodedData.append(contentsOf: EncodeSectorSixAndTwo(sector: [UInt8](block[0x100...0x1FF])))
                case 12:
                    let block = ProdosImage.readBlock(imageData: imageData, blockNum: (8 * index) + 3)
                    encodedData.append(contentsOf: EncodeSectorSixAndTwo(sector: [UInt8](block[0x000...0x0FF])))
                case 13:
                    let block = ProdosImage.readBlock(imageData: imageData, blockNum: (8 * index) + 7)
                    encodedData.append(contentsOf: EncodeSectorSixAndTwo(sector: [UInt8](block[0x000...0x0FF])))
                case 14:
                    let block = ProdosImage.readBlock(imageData: imageData, blockNum: (8 * index) + 3)
                    encodedData.append(contentsOf: EncodeSectorSixAndTwo(sector: [UInt8](block[0x100...0x1FF])))
                case 15:
                    let block = ProdosImage.readBlock(imageData: imageData, blockNum: (8 * index) + 7)
                    encodedData.append(contentsOf: EncodeSectorSixAndTwo(sector: [UInt8](block[0x100...0x1FF])))
                default:
                    encodedData.append(contentsOf: EncodeSectorSixAndTwo(sector: [UInt8](repeating: 0x4C, count: 343)))
                }
            }

            encodedData.append(contentsOf: dataEpilogue)
            
            //Gap2 - 20 bytes
            for _ in 0..<27 { encodedData.append(selfSync) }
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
        writtenData[0x56] = SixAndTwoTranslationTable[Int(encodedBuffer[0x100] ^ encodedBuffer[0x000])]
        
        for index in 0x00 ... 0xFE {
            writtenData[0x57 + index] = SixAndTwoTranslationTable[Int(encodedBuffer[index] ^ encodedBuffer[index + 1])]
        }

        for (i, index) in (0x100 ... 0x154).enumerated() {
            writtenData[85-i] = SixAndTwoTranslationTable[Int(encodedBuffer[index] ^ encodedBuffer[index + 1])]
        }
        
        writtenData[342] = SixAndTwoTranslationTable[Int(encodedBuffer[0xFF])]
        
        return writtenData
    }
    
    private func DecodeSectorSixAndTwo(nibbles: [UInt8]) -> [UInt8] {
        var sector = [UInt8](repeating: 0x00, count: 256)
        var readBuffer = [UInt8](repeating: 0x00, count: 343)
        
        readBuffer[0x155] = SixAndTwoDecode(byte: nibbles[0]) ^ 0
        
        for i in 1 ... 85 {
            readBuffer[0x155 - i] = SixAndTwoDecode(byte: nibbles[i]) ^ readBuffer[0x156 - i]
        }
        
        readBuffer[0x000] = SixAndTwoDecode(byte: nibbles[86]) ^ readBuffer[0x100]
            
        for i in 87 ... 341 {
            readBuffer[i - 86] = SixAndTwoDecode(byte: nibbles[i]) ^ readBuffer[i - 87]
        }
        
        var secondaryShift = 0
        for i in 0 ... 255 {
            let secondaryOffset = 0x100 + (0x55 - (i % 0x56))
            
            sector[i] |= readBuffer[i] << 2
            sector[i] |= GetSwappedLowBits(byte: readBuffer[secondaryOffset] >> secondaryShift)
            
            if(secondaryOffset == 0x100) {
                secondaryShift += 2
            }
        }
        
        return sector
    }
    
    private func GetSwappedLowBits(byte: UInt8) -> UInt8 {
        let b0 = byte & 0b00000001
        let b1 = byte & 0b00000010
        return UInt8((b0 << 1) | (b1 >> 1))
    }
    
    private func SixAndTwoPrenibblize(sector: [UInt8]) -> [UInt8] {
        //Create a nibblized 342-byte buffer from a 256-byte sector.
        var nibblized: [UInt8] = [UInt8](repeating: 0x00, count: 342)
        var secondaryShift = 0
        for (i, byte) in (0x00 ..< 0x100).enumerated() {
            nibblized[byte] = sector[byte] >> 2
            
            let secondaryOffset = 0x100 + (0x55 - (i % 0x56))
            nibblized[secondaryOffset] |= GetSwappedLowBits(byte: sector[byte]) << secondaryShift
            
            if(secondaryOffset == 0x100) {
                secondaryShift += 2
            }
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
    
    func SixAndTwoDecode(byte: UInt8) -> UInt8 {
        return UInt8(SixAndTwoTranslationTable.index(of: byte)!)
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

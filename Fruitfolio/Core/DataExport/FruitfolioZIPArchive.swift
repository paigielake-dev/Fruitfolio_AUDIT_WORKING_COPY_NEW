import Foundation
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

/// A stored (uncompressed) ZIP32 writer. Payloads stream in 1 MiB chunks;
/// only central-directory metadata is retained. This is an export, not encryption.
enum FruitfolioZIPArchive {
    enum Failure: Error { case invalidPath, duplicatePath, limitExceeded, cannotCreate, invalidSource, sourceChanged }
    enum Payload: Sendable { case bytes(Data), file(URL) }
    struct Entry: Sendable {
        let path: String
        let payload: Payload
    }
    private struct Central {
        let name: Data
        let crc: UInt32
        let size: UInt32
        let offset: UInt32
    }
    private static let crcTable: [UInt32] = (0..<256).map { index in
        var value = UInt32(index)
        for _ in 0..<8 { value = value & 1 == 0 ? value >> 1 : (value >> 1) ^ 0xedb88320 }
        return value
    }

    static func write(_ entries: [Entry], to output: URL) throws {
        guard entries.count <= Int(UInt16.max) else { throw Failure.limitExceeded }
        var paths = Set<String>()
        for entry in entries {
            guard !entry.path.isEmpty, entry.path.utf8.count <= Int(UInt16.max),
                  entry.path.utf8.allSatisfy({ (45...57).contains($0) || (65...90).contains($0) || (97...122).contains($0) || $0 == 95 }),
                  !entry.path.hasPrefix("/"),
                  entry.path.split(separator: "/", omittingEmptySubsequences: false).allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." }) else { throw Failure.invalidPath }
            guard paths.insert(entry.path).inserted else { throw Failure.duplicatePath }
        }
        try Task.checkCancellation()
        let descriptor = output.path.withCString { open($0, O_WRONLY | O_CREAT | O_EXCL, 0o600) }
        guard descriptor >= 0 else { throw Failure.cannotCreate }
        let file = FileHandle(fileDescriptor: descriptor, closeOnDealloc: true)
        var completed = false
        defer {
            try? file.close()
            if !completed { try? FileManager.default.removeItem(at: output) }
        }
        var position: UInt64 = 0
        func append(_ data: Data) throws {
            guard position + UInt64(data.count) <= UInt64(UInt32.max) else { throw Failure.limitExceeded }
            try file.write(contentsOf: data)
            position += UInt64(data.count)
        }
        func numbers(_ values: [(UInt32, Int)]) -> Data {
            var data = Data()
            for (number, count) in values {
                for index in 0..<count { data.append(UInt8(truncatingIfNeeded: number >> (index * 8))) }
            }
            return data
        }
        var central: [Central] = []
        for entry in entries {
            try Task.checkCancellation()
            let start = UInt32(position)
            let name = Data(entry.path.utf8)
            // General-purpose bit3: CRC/size follow the streamed payload.
            // DOS date1980-01-01 is fixed; actual timestamps remain in the manifest.
            try append(numbers([(0x04034b50,4),(20,2),(8,2),(0,2),(0,2),(33,2),(0,4),(0,4),(0,4),(UInt32(name.count),2),(0,2)]))
            try append(name)
            var crc: UInt32 = 0xffffffff
            var size: UInt64 = 0
            func consume(_ data: Data) throws {
                try Task.checkCancellation()
                size += UInt64(data.count)
                guard size <= UInt64(UInt32.max) else { throw Failure.limitExceeded }
                for byte in data { crc = (crc >> 8) ^ crcTable[Int((crc ^ UInt32(byte)) & 0xff)] }
                try append(data)
            }
            switch entry.payload {
            case .bytes(let data):
                for offset in stride(from: 0, to: data.count, by: 1_048_576) {
                    try consume(data.subdata(in: offset..<min(offset + 1_048_576, data.count)))
                }
            case .file(let url):
                let before = try FileManager.default.attributesOfItem(atPath: url.path)
                guard before[.type] as? FileAttributeType == .typeRegular,
                      let expectedSize = before[.size] as? NSNumber else { throw Failure.invalidSource }
                guard expectedSize.uint64Value <= UInt64(UInt32.max) else { throw Failure.limitExceeded }
                let inputDescriptor = url.path.withCString { open($0, O_RDONLY | O_NOFOLLOW) }
                guard inputDescriptor >= 0 else { throw Failure.invalidSource }
                let input = FileHandle(fileDescriptor: inputDescriptor, closeOnDealloc: true)
                defer { try? input.close() }
                var status = stat()
                guard fstat(inputDescriptor, &status) == 0,
                      UInt64(status.st_size) == expectedSize.uint64Value,
                      UInt64(status.st_ino) == (before[.systemFileNumber] as? NSNumber)?.uint64Value else { throw Failure.sourceChanged }
                while let chunk = try input.read(upToCount: 1_048_576), !chunk.isEmpty { try consume(chunk) }
                let after = try FileManager.default.attributesOfItem(atPath: url.path)
                guard size == expectedSize.uint64Value,
                      before[.modificationDate] as? Date == after[.modificationDate] as? Date,
                      before[.systemFileNumber] as? NSNumber == after[.systemFileNumber] as? NSNumber else { throw Failure.sourceChanged }
            }
            let checksum = crc ^ 0xffffffff
            try append(numbers([(0x08074b50,4),(checksum,4),(UInt32(size),4),(UInt32(size),4)]))
            central.append(Central(name: name, crc: checksum, size: UInt32(size), offset: start))
        }
        let centralStart = UInt32(position)
        for entry in central {
            try Task.checkCancellation()
            try append(numbers([(0x02014b50,4),(20,2),(20,2),(8,2),(0,2),(0,2),(33,2),(entry.crc,4),
                                (entry.size,4),(entry.size,4),(UInt32(entry.name.count),2),(0,2),(0,2),(0,2),(0,2),(0,4),(entry.offset,4)]))
            try append(entry.name)
        }
        let centralSize = UInt32(position) - centralStart
        try append(numbers([(0x06054b50,4),(0,2),(0,2),(UInt32(central.count),2),(UInt32(central.count),2),
                            (centralSize,4),(centralStart,4),(0,2)]))
        try Task.checkCancellation()
        try file.synchronize()
        try file.close()
        completed = true
    }
}

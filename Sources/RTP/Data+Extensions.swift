import Foundation

extension Data {
	// big returns a big-endian integer of type T extracted from the bytes at the specified offset.
	func big<T: FixedWidthInteger>(at offset: Int) -> T {
		var value: T = 0
		withUnsafeMutablePointer(to: &value) {
			self.copyBytes(to: UnsafeMutableBufferPointer(start: $0, count: 1), from: offset..<offset + MemoryLayout<T>.size)
		}
		return T(bigEndian: value)
	}

	// big returns a little-endian integer of type T extracted from the bytes at the specified offset.
	func little<T: FixedWidthInteger>(at offset: Int) -> T {
		var value: T = 0
		withUnsafeMutablePointer(to: &value) {
			self.copyBytes(to: UnsafeMutableBufferPointer(start: $0, count: 1), from: offset..<offset + MemoryLayout<T>.size)
		}
		return T(littleEndian: value)
	}
}

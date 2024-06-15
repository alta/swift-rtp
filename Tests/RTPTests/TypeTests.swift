import XCTest

@testable import RTP

class TypeTests: XCTestCase {
	func testMemorySizes() {
		XCTAssertEqual(MemoryLayout<RTP.PayloadType>.size, 1)
		XCTAssertEqual(MemoryLayout<RTP.SourceID>.size, 4)
		XCTAssertEqual(MemoryLayout<RTP.SequenceNumber>.size, 2)
		XCTAssertEqual(MemoryLayout<RTP.Timestamp>.size, 4)
	}

	func testPacketizerIncrementOverflow() {
		var packetizer = RTP.Packetizer(for: .opus, sequenceNumber: .max, timestamp: .max)

		packetizer.increment(48000)
		XCTAssertEqual(packetizer.sequenceNumber, 0)
		XCTAssertEqual(packetizer.timestamp, 48000 - 1)

		packetizer.increment(48000)
		XCTAssertEqual(packetizer.sequenceNumber, 1)
		XCTAssertEqual(packetizer.timestamp, 48000 * 2 - 1)
	}

	func testPacketInitWithData() throws {
		let bytes: [UInt8] = [
			2 << 6,  // Version 2, no marker or extension
			111,  // Opus payload type
			0, 123,  // Sequence number 123
			0, 0, 0, 1,  // Timestamp 1
			0, 255, 255, 255,  // SSRC 0x00FFFFFF
		]

		let packet = try RTP.Packet(from: Data(bytes))

		XCTAssertEqual(packet.payloadType, .opus)
		XCTAssertEqual(packet.sequenceNumber, 123)
		XCTAssertEqual(packet.timestamp, 1)
		XCTAssertEqual(packet.ssrc, 0x00FF_FFFF)
	}
}

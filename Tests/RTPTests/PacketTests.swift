import XCTest

@testable import RTP

class PacketTests: XCTestCase {
	func testInitWithData() throws {
		let bytes: [UInt8] = [
			2 << 6, // Version 2, no marker or extension
			111, // Opus payload type
			0, 123, // Sequence number 123
			0, 0, 0, 1, // Timestamp 1
			0, 255, 255, 255, // SSRC 0x00FFFFFF
		]

		let packet = try RTP.Packet(from: Data(bytes))

		XCTAssertEqual(packet.payloadType, .opus)
		XCTAssertEqual(packet.sequenceNumber, 123)
		XCTAssertEqual(packet.timestamp, 1)
		XCTAssertEqual(packet.ssrc, 0x00FF_FFFF)
	}
}

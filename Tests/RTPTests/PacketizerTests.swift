import XCTest

@testable import RTP

class PacketizerTests: XCTestCase {
	func testIncrementOverflow() {
		var packetizer = RTP.Packetizer(for: .opus, sequenceNumber: .max, timestamp: .max)

		packetizer.increment(48000)
		XCTAssertEqual(packetizer.sequenceNumber, 0)
		XCTAssertEqual(packetizer.timestamp, 48000 - 1)

		packetizer.increment(48000)
		XCTAssertEqual(packetizer.sequenceNumber, 1)
		XCTAssertEqual(packetizer.timestamp, 48000 * 2 - 1)
	}
}

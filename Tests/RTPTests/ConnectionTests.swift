#if canImport(Network)

	import Network
	import XCTest

	@testable import RTP

	class RTPConnectionTests: XCTestCase {
		func testConnectionStop() {
			let conn = RTP.Connection(host: "localhost", port: 12345) { _ in }
			XCTAssertEqual(conn.conn.state, .setup)
			conn.start()
			sleep(1)
			XCTAssertEqual(conn.conn.state, .ready)
			conn.stop()
			sleep(1)
			XCTAssertEqual(conn.conn.state, .cancelled)
			conn.conn.restart()
			sleep(1)
			XCTAssertEqual(conn.conn.state, .cancelled)  // NWConnection instances cannot be restarted once cancelled
		}
	}

#endif

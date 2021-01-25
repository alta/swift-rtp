import Foundation
import Network

public class Connection {
	public typealias ReceiverBlock = (Packet) -> Void

	public static let defaultQueue = DispatchQueue(label: "rtp")

	var queue: DispatchQueue
	var receiverBlock: ReceiverBlock
	var conn: NWConnection

	public init(host: NWEndpoint.Host, port: NWEndpoint.Port, queue: DispatchQueue = Connection.defaultQueue, receiverBlock: @escaping ReceiverBlock) {
		print("Opening RTP connection to \(host):\(port)…")
		self.queue = queue
		self.receiverBlock = receiverBlock
		conn = NWConnection(host: host, port: port, using: .udp)
	}

	deinit {
		stop()
	}

	public func start() {
		print("Starting RTP connection to \(conn.endpoint)…")
		conn.start(queue: queue)
		receive()
	}

	public func stop() {
		conn.cancel()
	}

	public func send(_ packet: Packet) {
		let data = packet.encode()
		// print("Sending RTP packet: \(packet.ssrc) \(packet.sequenceNumber) to \(conn.endpoint)")
		conn.send(content: data, completion: .contentProcessed(contentProcessed))
	}

	func contentProcessed(error: NWError?) {
		if let error = error {
			print("Error sending UDP packet: \(error)")
		}
	}

	func receive() {
		conn.receiveMessage { [weak self] data, _, _, error in
			if let error = error {
				print("Error receiving UDP packet: \(error)")
				return
			} else if let data = data {
				// print("⬇️ Received UDP packet of size: \(data.count)")

				do {
					let packet = try Packet(from: data)
					// print("🅿️ Parsed RTP packet: \(packet)")
					self?.receiverBlock(packet)
				} catch {
					print("Error handling RTP: \(error)")
					return
				}
			}
			self?.receive()
		}
	}
}

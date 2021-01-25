import Foundation

// Sequencer is an internal glue protocol to allow a Packetizer to easily create Packets.
// It should not be created directly.
protocol Sequencer {
	var payloadType: PayloadType { get }
	var ssrc: SourceID { get }
	var sequenceNumber: SequenceNumber { get }
	var timestamp: Timestamp { get }
}

// A Packetizer emits a sequence of RTP packets with monotonic sequence numbers.
public struct Packetizer: Sequencer {
	public let payloadType: PayloadType
	public let ssrc: SourceID
	public var sequenceNumber: SequenceNumber
	public var timestamp: Timestamp

	public init(
		for payloadType: PayloadType,
		ssrc: SourceID = .random(),
		sequenceNumber: SequenceNumber = SequenceNumber.random(),
		timestamp: Timestamp = Timestamp.random()
	) {
		self.payloadType = payloadType
		self.ssrc = ssrc
		self.sequenceNumber = sequenceNumber
		self.timestamp = timestamp
	}

	mutating func increment(_ samples: Timestamp) {
		(sequenceNumber, _) = sequenceNumber.addingReportingOverflow(1)
		(timestamp, _) = timestamp.addingReportingOverflow(samples)
	}

	public mutating func packetize(_ payload: Data, _ samples: Timestamp) throws -> Packet {
		let packet = try Packet(self, payload: payload)
		increment(samples)
		return packet
	}
}

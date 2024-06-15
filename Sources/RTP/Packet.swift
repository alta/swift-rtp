import Foundation

// Packet represents an individual RTP packet.
public struct Packet {
	static let version: UInt8 = 2
	static let versionMask: UInt8 = 0b1100_0000
	static let paddingMask: UInt8 = 0b0010_0000
	static let extensionMask: UInt8 = 0b0001_0000
	static let csrcCountOffset = 0
	static let csrcCountMask: UInt8 = 0b0000_1111
	static let maxCSRCs = 15
	static let markerOffset = 1
	static let markerMask: UInt8 = 0b1000_0000
	static let payloadTypeOffset = 1
	static let payloadTypeMask: UInt8 = 0b0111_1111
	static let sequenceOffset = 2
	static let timestampOffset = 4
	static let ssrcOffset = 8
	static let csrcOffset = 12
	static let headerSize = csrcOffset

	public let payloadType: PayloadType
	public let marker: Bool
	public let sequenceNumber: SequenceNumber
	public let timestamp: Timestamp
	public let ssrc: SourceID
	public let csrcs: [SourceID]?
	public let `extension`: Extension?
	public let payload: Data
	public let padding: UInt8

	var payloadWithoutPadding: Data {
		payload[0..<payload.count - Int(padding)]
	}

	var encodedSize: Int {
		let csrcsSize = csrcs?.count ?? 0 * MemoryLayout<SourceID>.size
		let extensionSize = `extension`?.encodedSize ?? 0
		return Self.headerSize + csrcsSize + extensionSize + payload.count + Int(padding)
	}

	// TODO: add extension data
	init(_ sequencer: Sequencer, payload: Data) throws {
		try self.init(
			payloadType: sequencer.payloadType,
			payload: payload,
			ssrc: sequencer.ssrc,
			sequenceNumber: sequencer.sequenceNumber,
			timestamp: sequencer.timestamp
		)
	}

	// TODO: add extension data
	public init(payloadType: PayloadType, payload: Data, ssrc: SourceID, sequenceNumber: SequenceNumber, timestamp: Timestamp, padding: UInt8 = 0, marker: Bool = false, csrcs: [SourceID]? = nil) throws {
		if let csrcs = csrcs {
			if csrcs.count > Self.maxCSRCs {
				throw EncodingError.tooManyCSRCs(csrcs.count)
			}
		}

		self.payloadType = payloadType
		self.marker = marker
		self.sequenceNumber = sequenceNumber
		self.timestamp = timestamp
		self.ssrc = ssrc
		self.csrcs = csrcs
		`extension` = nil
		self.payload = payload
		self.padding = padding
	}

	public init(from data: Data) throws {
		if data.count < Self.headerSize {
			throw EncodingError.dataTooSmall(Self.headerSize)
		}

		// Parse first octect (version, padding, extension)
		let version = (data[0] & Self.versionMask) >> 6
		if version != Self.version {
			throw EncodingError.unknownVersion(version)
		}
		let hasPadding = (data[0] & Self.paddingMask) != 0
		let hasExtension = (data[0] & Self.extensionMask) != 0
		let sizeWithPaddingAndExtension = Self.headerSize + (hasPadding ? 1 : 0) + (hasExtension ? Extension.headerSize : 0)

		// Parse second octet
		marker = (data[Self.markerOffset] & Self.markerMask) != 0
		let csrcCount = Int(data[Self.csrcCountOffset] & Self.csrcCountMask)
		let csrcSize = csrcCount * MemoryLayout<SourceID>.size
		let sizeWithCSRCs = sizeWithPaddingAndExtension + csrcSize
		if data.count < sizeWithCSRCs {
			throw EncodingError.dataTooSmall(sizeWithCSRCs)
		}
		payloadType = PayloadType(data[Self.payloadTypeOffset] & Self.payloadTypeMask)

		// Parse sequence number from octets 3-4
		sequenceNumber = data.big(at: Self.sequenceOffset)

		// Parse timestamp from octets 5-8
		timestamp = data.big(at: Self.timestampOffset)

		// Parse SSRC from octets 9-12
		ssrc = data.big(at: Self.ssrcOffset)

		// Parse optional CSRCs in octets 13+
		if csrcCount > 0 {
			csrcs = (0..<csrcCount).map {
				data.big(at: Self.csrcOffset + $0)
			}
		}
		else {
			csrcs = nil
		}

		// Read extension
		let extensionOffset = Self.csrcOffset + csrcSize
		`extension` = hasExtension ? try Extension(from: data[extensionOffset...]) : nil

		// Read payload
		let payloadOffset = extensionOffset + (`extension`?.encodedSize ?? 0)
		padding = hasPadding ? UInt8(data[data.count - 1]) : 0
		if data.count - payloadOffset - Int(padding) < 0 {
			throw EncodingError.paddingTooLarge(padding)
		}
		payload = data[payloadOffset...]
	}

	public func encode() -> Data {
		var data = Data(capacity: encodedSize)

		// Encode first octect (version, padding, extension)
		data.append(contentsOf: [(Self.version << 6 & Self.versionMask) | (padding > 0 ? Self.paddingMask : 0) | (`extension` != nil ? Self.extensionMask : 0) | (UInt8(csrcs?.count ?? 0) & Self.csrcCountMask)])

		// Encode second octet
		data.append(contentsOf: [(marker ? Self.markerMask : 0) | (payloadType.rawValue & Self.payloadTypeMask)])

		// Encode sequence number
		data.append(contentsOf: [UInt8(sequenceNumber >> 8 & 0xFF), UInt8(sequenceNumber & 0xFF)])

		// Encode timestamp
		data.append(contentsOf: [UInt8(timestamp >> 24 & 0xFF), UInt8(timestamp >> 16 & 0xFF), UInt8(timestamp >> 8 & 0xFF), UInt8(timestamp & 0xFF)])

		// Encode SSRC
		data.append(contentsOf: [UInt8(ssrc >> 24 & 0xFF), UInt8(ssrc >> 16 & 0xFF), UInt8(ssrc >> 8 & 0xFF), UInt8(ssrc & 0xFF)])

		// Encode CSRCs
		if let csrcs = csrcs {
			for i in 0..<csrcs.count {
				data.append(contentsOf: [UInt8(csrcs[i] >> 24 & 0xFF), UInt8(csrcs[i] >> 16 & 0xFF), UInt8(csrcs[i] >> 8 & 0xFF), UInt8(csrcs[i] & 0xFF)])
			}
		}

		// Encode extension
		if let ext = `extension` {
			data.append(contentsOf: [UInt8(ext.profileID >> 8 & 0xFF), UInt8(ext.profileID & 0xFF)])
			let wordCount = ext.payload.count / MemoryLayout<UInt32>.size
			data.append(contentsOf: [UInt8(wordCount >> 8 & 0xFF), UInt8(wordCount & 0xFF)])
			data.append(ext.payload)
		}

		// Encode payload
		data.append(payloadWithoutPadding)

		// Encode padding
		if padding > 0 {
			data.append(Data(count: Int(padding) - 1))
			data.append(contentsOf: [padding])
		}

		return data
	}
}

// Extension represents an RTP extension.
public struct Extension {
	public typealias ProfileID = UInt16

	static let headerSize = 4
	static let profileIDOffset = 0
	static let sizeOffset = 2

	public let profileID: ProfileID
	public let payload: Data

	public var encodedSize: Int {
		Self.headerSize + payload.count
	}

	public init(from data: Data) throws {
		if data.count < Self.headerSize {
			throw EncodingError.extensionDataTooSmall(Self.headerSize)
		}

		profileID = data.big(at: Self.profileIDOffset)
		let payloadSize = data.big(at: Self.sizeOffset) * MemoryLayout<UInt32>.size
		let size = Self.headerSize + payloadSize
		if data.count < size {
			throw EncodingError.extensionDataTooSmall(size)
		}

		payload = data[Self.headerSize..<size]
	}
}

/*

 RTP header format: https://tools.ietf.org/html/rfc3550#section-5

 0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
 +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 |V=2|P|X|  CC   |M|     PT      |       sequence number         |
 +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 |                           timestamp                           |
 +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 |           synchronization source (SSRC) identifier            |
 +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+
 |            contributing source (CSRC) identifiers             |
 |                             ....                              |
 +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

 Header extension: https://tools.ietf.org/html/rfc3550#section-5.3.1

 0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
 +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 |      defined by profile       |           length              |
 +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 |                        header extension                       |
 |                             ....                              |

 */

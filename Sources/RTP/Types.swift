import Foundation

public enum EncodingError: Error {
	case malformedHeader
	case unsupportedPayloadType(_ payloadType: PayloadType)
	case unknownVersion(_ version: UInt8)
	case dataTooSmall(_ expected: Int)
	case extensionDataTooSmall(_ expected: Int)
	case paddingTooLarge(_ padding: UInt8)
	case tooManyCSRCs(_ count: Int)
}

public struct PayloadType: ExpressibleByIntegerLiteral, RawRepresentable, Equatable {
	public typealias IntegerLiteralType = UInt8

	public static let marker: Self = 0b1000_0000
	public static let opus: Self = 111

	public var rawValue: IntegerLiteralType

	public init(integerLiteral value: IntegerLiteralType) {
		rawValue = value
	}

	public init?(rawValue: IntegerLiteralType) {
		self.rawValue = rawValue
	}

	public init(_ value: IntegerLiteralType) {
		self.init(integerLiteral: value)
	}
}

public typealias SourceID = UInt32
public typealias SequenceNumber = UInt16
public typealias Timestamp = UInt32

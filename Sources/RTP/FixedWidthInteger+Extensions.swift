import Foundation

public extension FixedWidthInteger {
	// random is a convenience function to generate a random value of the concrete type in [min,max]
	static func random() -> Self {
		Self.random(in: .min ... .max)
	}
}

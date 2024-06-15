import Foundation

extension FixedWidthInteger {
	// random is a convenience function to generate a random value of the concrete type in [min,max]
	public static func random() -> Self {
		Self.random(in: .min ... .max)
	}
}

// swift-tools-version:5.3
import PackageDescription

let package = Package(
	name: "RTP",
	platforms: [
		.macOS(.v10_14),
		.iOS(.v12),
	],
	products: [
		.library(
			name: "RTP",
			targets: ["RTP"]
		)
	],
	dependencies: [],
	targets: [
		.target(
			name: "RTP",
			dependencies: []
		),
		.testTarget(
			name: "RTPTests",
			dependencies: ["RTP"]
		),
	]
)

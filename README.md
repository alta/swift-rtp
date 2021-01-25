# Swift RTP

Basic [RTP](https://en.wikipedia.org/wiki/Real-time_Transport_Protocol) (Real-time Transport protocol) in Swift. This package enables basic RTP packet encoding and decoding and transmission on Apple platforms (iOS, macOS, watchOS, tvOS). This was built for a now-defunct audio app for iOS and macOS, and runs reliably with multiple 48khz Opus audio channels over a typical 4G connection on modern iPhone devices.

## Installation

Use Swift Package Manager to add this to your Xcode project or Swift package.

## Security

**Note:** this package does *not* handle encryption or secure transmission of RTP data. It is up to consumers of this package to wrap the connection in some form of secure protocol using DTLS or QUIC.
## Author

© Alta Software, LLC

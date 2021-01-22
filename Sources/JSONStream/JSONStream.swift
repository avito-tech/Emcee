import Foundation

/// A basic interface that allows JSONReader to read the stream symbol by symbol, consuming the JSON element by element
/// rather than having the whole JSON object availbla to parse upfront.
public protocol JSONStream {
    /// Provides back a next scalar without actually moving a pointer. Returns nil if no more data avaiable.
    func touch() -> UInt8?
    /// Moves a pointer to the next scalar and provides it back. Returns nil if no more data avaiable.
    func read() -> UInt8?
    /// Closes the stream.
    func close()
}

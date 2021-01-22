import Foundation

public protocol JSONReaderEventStream {
    /** Called when JSON reader consumes a root JSON array. */
    func newArray(_ array: NSArray, data: Data)
    /** Called when JSON reader consumes a root JSON object. */
    func newObject(_ object: NSDictionary, data: Data)
}

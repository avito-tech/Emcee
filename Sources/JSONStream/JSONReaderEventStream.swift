import Foundation

public protocol JSONReaderEventStream {
    /** Called when JSON reader consumes a root JSON array. */
    func newArray(_ array: NSArray, scalars: [Unicode.Scalar])
    /** Called when JSON reader consumes a root JSON object. */
    func newObject(_ object: NSDictionary, scalars: [Unicode.Scalar])
}

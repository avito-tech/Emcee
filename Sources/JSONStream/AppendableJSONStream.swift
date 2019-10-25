import Foundation

public protocol AppendableJSONStream: JSONStream {
    func append(scalars: [Unicode.Scalar])
}

public extension AppendableJSONStream {
    func append(data: Data) {
        append(scalars: data.map { Unicode.Scalar($0) })
    }
}

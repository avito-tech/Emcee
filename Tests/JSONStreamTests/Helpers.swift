import Foundation
import JSONStream

class FakeJSONStream: JSONStream {
    var data: [Unicode.Scalar]
    var isClosed = false
    
    public init(string: String) {
        data = Array(string.unicodeScalars).reversed()
    }
    
    func read() -> Unicode.Scalar? {
        guard let last = data.last else { return nil }
        data.removeLast()
        return last
    }
    
    func touch() -> Unicode.Scalar? {
        return data.last
    }
    
    func close() {
        isClosed = true
    }
}

class FakeEventStream: JSONReaderEventStream {
    var all = [NSObject]()
    var allObjects = [NSDictionary]()
    var allArrays = [NSArray]()
    var allScalars = [[Unicode.Scalar]]()
    
    public init() {}
    
    func newArray(_ array: NSArray, scalars: [Unicode.Scalar]) {
        all.append(array)
        allArrays.append(array)
        allScalars.append(scalars)
    }
    
    func newObject(_ object: NSDictionary, scalars: [Unicode.Scalar]) {
        all.append(object)
        allObjects.append(object)
        allScalars.append(scalars)
    }
}

import Foundation
import JSONStream

class FakeJSONStream: JSONStream {
    var data: [UInt8]
    var isClosed = false
    
    public init(string: String) {
        data = [UInt8](string.utf8).reversed()
    }
    
    func read() -> UInt8? {
        guard let last = data.last else { return nil }
        data.removeLast()
        return last
    }
    
    func touch() -> UInt8? {
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
    var allData = [Data]()
    
    public init() {}
    
    func newArray(_ array: NSArray, data: Data) {
        all.append(array)
        allArrays.append(array)
        allData.append(data)
    }
    
    func newObject(_ object: NSDictionary, data: Data) {
        all.append(object)
        allObjects.append(object)
        allData.append(data)
    }
}

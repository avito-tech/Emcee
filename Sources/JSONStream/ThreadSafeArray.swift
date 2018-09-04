import Dispatch
import Foundation

final class ThreadSafeArray<Element> {
    private var array = [Element]()
    private let queue = DispatchQueue(label: "ru.avito.ConcurrentArray.queue")
    
    public init() {}
    
    public var isEmpty: Bool {
        return queue.sync { array.isEmpty }
    }
    
    public var last: Element? {
        return queue.sync { array.last }
    }
    
    public func insert<S>(contentsOf newElements: S, at i: Array<Element>.Index) where S : Collection, Element == S.Element {
        queue.sync { array.insert(contentsOf: newElements, at: i) }
    }
    
    public func removeLast() -> Element {
        return queue.sync { array.removeLast() }
    }
}

import Foundation

final class MutatingIterator {
    
    public enum Result {
        case `continue`
        case `break`
        case removeAndContinue
    }
    
    public static func iterate<Element>(_ array: inout Array<Element>, processor: (Element) throws -> Result) rethrows {
        var indexesToRemove = IndexSet()
        iteratorLoop: for i in array.startIndex ..< array.endIndex {
            let element = array[i]
            let result = try processor(element)
            switcher: switch result {
            case .continue:
                break switcher
            case .break:
                break iteratorLoop
            case .removeAndContinue:
                indexesToRemove.insert(i)
                break switcher
            }
        }
        
        array.remove(at: indexesToRemove)
    }
}

private extension Array {
    mutating func remove(at indexes : IndexSet) {
        guard var i = indexes.first, i < count else { return }
        var j = index(after: i)
        var k = indexes.integerGreaterThan(i) ?? endIndex
        while j != endIndex {
            if k != j { swapAt(i, j); formIndex(after: &i) }
            else { k = indexes.integerGreaterThan(k) ?? endIndex }
            formIndex(after: &j)
        }
        removeSubrange(i...)
    }
}

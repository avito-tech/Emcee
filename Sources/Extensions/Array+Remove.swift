import Foundation

public extension Array {
    @discardableResult
    mutating func avito_removeAll(match: (Iterator.Element) -> (Bool)) -> [Iterator.Element] {
        var removedElements: [Iterator.Element] = []
        for (index, element) in enumerated().reversed() {
            if match(element) {
                removedElements.insert(remove(at: index), at: 0)
            }
        }
        return removedElements
    }
}

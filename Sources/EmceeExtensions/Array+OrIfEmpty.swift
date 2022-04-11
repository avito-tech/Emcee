import Foundation

public extension Array {
    func orIfEmpty(_ alternativeArray: [Element]) -> [Element] {
        if isEmpty {
            return alternativeArray
        }
        return self
    }
}

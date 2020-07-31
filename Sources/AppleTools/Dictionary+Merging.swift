import Foundation

public extension Dictionary {
    func byMergingWith(_ dictionary: [Key: Value]) -> [Key: Value] {
        var newDict = self
        dictionary.forEach { (entry: (key: Key, value: Value)) in
            newDict.updateValue(entry.value, forKey: entry.key)
        }
        return newDict
    }
}

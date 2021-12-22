import Foundation
import PlistLib

extension PlistEntry {
    
    /// Compares current entry against other. If other contains anything that current does not contain, returns `false`.
    /// Useful for comparing dict entries, allowing to compare specific set of keys and their values in current entry against ones on `other`.
    /// Examples:
    ///
    /// This returns `true`:
    /// ```
    /// PlistEntry.dict(
    ///     ["key": .string("value"), "otherKey": .string("other value")]
    /// ).containsSameValues(asInPlistEntry: PlistEntry.dict(
    ///     ["key": .string("value")]
    /// )
    /// ```
    ///
    /// These return `false`:
    /// ```
    /// PlistEntry.dict(
    ///     ["otherKey": .string("other value")]
    /// ).containsSameValues(asInPlistEntry: PlistEntry.dict(
    ///     ["key": .string("value")]
    /// )
    ///
    /// PlistEntry.dict(
    ///     ["key": .bool(true)]
    /// ).containsSameValues(asInPlistEntry: PlistEntry.dict(
    ///     ["key": .string("value")]
    /// )
    /// ```
    ///
    public func containsSameValues(asInPlistEntry other: PlistEntry) -> Bool {
        switch (self, other) {
        case (.array(let left), .array(let right)):
            guard left.count == right.count else { return false }
            
            return zip(left, right).allSatisfy { left, right in
                if let left = left, let right = right {
                    return left.containsSameValues(asInPlistEntry: right)
                } else {
                    return left == right
                }
            }
        case (.bool(let left), .bool(let right)):
            return left == right
        case (.data(let left), .data(let right)):
            return left == right
        case (.date(let left), .date(let right)):
            return left == right
        case (.dict(let left), .dict(let right)):
            return right.allSatisfy { (key: String, rightValue: PlistEntry?) in
                let leftValue = left[key]
                return leftValue == rightValue
            }
        case (.number(let left), .number(let right)):
            return left == right
        case (.string(let left), .string(let right)):
            return left == right
        default:
            return false
        }
    }
}

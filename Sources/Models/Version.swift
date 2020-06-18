public final class Version: NewStringType { }

extension Array: Comparable where Element == Version {
    public static func < (lhs: Array<Version>, rhs: Array<Version>) -> Bool {
        if lhs.count < rhs.count {
            return true
        } else if lhs.count > rhs.count {
            return false
        }
        
        let sortedLeft = lhs.sorted { $0 > $1 }
        let sortedRight = rhs.sorted { $0 > $1 }
        
        for i in 0..<sortedLeft.count {
            if sortedLeft[i] < sortedRight[i] {
                return true
            } else if sortedLeft[i] > sortedRight[i] {
                return false
            }
        }
        
        return false
    }
}

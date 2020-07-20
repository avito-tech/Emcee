import Types

public final class Port: NewIntType, Strideable {
    public typealias Stride = Int
    
    public func distance(to other: Port) -> Int {
        other.value - self.value
    }
    
    public func advanced(by n: Int) -> Self {
        return type(of: self).init(value: value + n)
    }
}

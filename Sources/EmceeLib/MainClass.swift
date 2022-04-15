import Foundation

public final class Main {
    public init() {}
    
    public func main() -> Int32 {
        do {
            try InProcessMain().run()
            return 0
        } catch {
            print("\(error)")
            fatalError("\(error)")
            return 1
        }
    }
}

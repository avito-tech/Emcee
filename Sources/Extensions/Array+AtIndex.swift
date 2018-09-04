import Foundation

public extension Array {
    func elementAtIndex(_ index: Int, _ description: String) -> Element {
        guard index < self.count else {
            fatalError("\(description) failed: index \(index) is out of bounds, all objects: \(self).")
        }
        return self[index]
    }
}

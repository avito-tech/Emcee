import Foundation
import OrderedSet

public final class Arguments: Equatable, ExpressibleByArrayLiteral {
    public let argumentDescriptions: OrderedSet<ArgumentDescription>

    public static let empty = Arguments([])
    
    public init(
        _ argumentDescriptions: OrderedSet<ArgumentDescription>
    ) {
        self.argumentDescriptions = argumentDescriptions
    }

    // MARK: - ExpressibleByArrayLiteral

    public typealias ArrayLiteralElement = ArgumentDescription

    public convenience init(arrayLiteral elements: ArgumentDescription...) {
        self.init(OrderedSet(sequence: elements))
    }

    // MARK: - Equatable

    public static func == (left: Arguments, right: Arguments) -> Bool {
        return left.argumentDescriptions == right.argumentDescriptions
    }
}

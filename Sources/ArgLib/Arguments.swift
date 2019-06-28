import Foundation
import OrderedSet

public final class Arguments {
    public let argumentDescriptions: OrderedSet<ArgumentDescription>
    
    public init(
        _ argumentDescriptions: OrderedSet<ArgumentDescription>
    ) {
        self.argumentDescriptions = argumentDescriptions
    }
}

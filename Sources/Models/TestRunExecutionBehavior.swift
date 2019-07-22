import Foundation

/** Defines the specifics of the behavior of the test run. */
public struct TestRunExecutionBehavior: Codable, Equatable {
    
    /** Maximum number of simulators to create and use in parallel. */
    public let numberOfSimulators: UInt

    public init(
        numberOfSimulators: UInt
    ) {
        self.numberOfSimulators = numberOfSimulators
    }
}

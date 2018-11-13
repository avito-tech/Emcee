import Foundation
import Models

public protocol ScheduleStrategy: CustomStringConvertible {
    func generateBuckets(
        numberOfDestinations: UInt,
        testEntries: [TestEntry],
        testDestination: TestDestination,
        toolResources: ToolResources,
        buildArtifacts: BuildArtifacts)
        -> [Bucket] 
}

public extension ScheduleStrategyType {
    func scheduleStrategy() -> ScheduleStrategy {
        switch self {
        case .individual:
            return IndividualScheduleStrategy()
        case .equallyDivided:
            return EquallyDividedScheduleStrategy()
        case .progressive:
            return ProgressiveScheduleStrategy()
        }
    }
}

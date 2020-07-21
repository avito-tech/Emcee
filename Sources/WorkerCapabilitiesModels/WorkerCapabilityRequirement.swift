import Foundation

public struct WorkerCapabilityRequirement: Codable, Equatable {
    public let name: WorkerCapabilityName
    public let constraint: WorkerCapabilityConstraint
    
    public init(
        capabilityName: WorkerCapabilityName,
        constraint: WorkerCapabilityConstraint
    ) {
        self.name = capabilityName
        self.constraint = constraint
    }
}

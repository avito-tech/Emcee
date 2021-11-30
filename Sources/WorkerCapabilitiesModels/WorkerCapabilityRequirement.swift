import Foundation

public struct WorkerCapabilityRequirement: Codable, Hashable, CustomStringConvertible {
    public let capabilityName: WorkerCapabilityName
    public let constraint: WorkerCapabilityConstraint
    
    public init(
        capabilityName: WorkerCapabilityName,
        constraint: WorkerCapabilityConstraint
    ) {
        self.capabilityName = capabilityName
        self.constraint = constraint
    }
    
    public var description: String {
        "<\(type(of: self)) capability name: \"\(capabilityName.value)\", constraint: \(constraint)>"
    }
}

extension WorkerCapabilityRequirement {
    public static func matching(workerCapability: WorkerCapability) -> Self {
        Self(capabilityName: workerCapability.name, constraint: .equal(workerCapability.value))
    }
}

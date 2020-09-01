import Foundation
import WorkerCapabilitiesModels

public final class WorkerCapabilityConstraintResolver {
    public init() {}
    
    public func requirementsSatisfied(
        requirements: Set<WorkerCapabilityRequirement>,
        workerCapabilities: Set<WorkerCapability>
    ) -> Bool {
        for requirement in requirements {
            let matchingCapabilities = matchingWorkerCapabilities(withName: requirement.capabilityName, workerCapabilities: workerCapabilities)
            
            if matchingCapabilities.isEmpty {
                if !isConstraintSatisfied(requirement.constraint, workerCapability: nil) {
                    return false
                }
            } else {
                var anyMatch = false
                for matchingCapability in matchingCapabilities {
                    if isConstraintSatisfied(requirement.constraint, workerCapability: matchingCapability) {
                        anyMatch = anyMatch || true
                    }
                }
                if !anyMatch {
                    return false
                }
            }
        }
        return true
    }
    
    private func isConstraintSatisfied(
        _ constraint: WorkerCapabilityConstraint,
        workerCapability: WorkerCapability?
    ) -> Bool {
        switch constraint {
        case .absent:
            return workerCapability == nil
        case .equal(let expectedValue):
            guard let value = workerCapability?.value else { return false }
            return expectedValue == value
        case .lessThan(let valueToCompare):
            guard let value = workerCapability?.value else { return false }
            if let left = Double(value), let right = Double(valueToCompare) {
                return left < right
            }
            return value < valueToCompare
        case .greaterThan(let valueToCompare):
            guard let value = workerCapability?.value else { return false }
            if let left = Double(value), let right = Double(valueToCompare) {
                return left > right
            }
            return value > valueToCompare
        case .not(let constraint):
            return !isConstraintSatisfied(constraint, workerCapability: workerCapability)
        case .all(let constraints):
            for constraint in constraints {
                if !isConstraintSatisfied(constraint, workerCapability: workerCapability) {
                    return false
                }
            }
            return true
        case .any(let constraints):
            for constraint in constraints {
                if isConstraintSatisfied(constraint, workerCapability: workerCapability) {
                    return true
                }
            }
            return false
        }
    }
    
    private func matchingWorkerCapabilities(
        withName name: WorkerCapabilityName,
        workerCapabilities: Set<WorkerCapability>
    ) -> [WorkerCapability] {
        workerCapabilities.filter { $0.name == name }
    }
}

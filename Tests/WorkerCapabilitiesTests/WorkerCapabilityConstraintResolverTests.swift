import WorkerCapabilities
import WorkerCapabilitiesModels
import XCTest

final class WorkerCapabilityConstraintResolverTests: XCTestCase {
    lazy var workerCapabilityConstraintResolver = WorkerCapabilityConstraintResolver()
    
    func test() {
        XCTAssertTrue(
            workerCapabilityConstraintResolver.requirementsSatisfied(requirements: [], workerCapabilities: [])
        )
    }
    
    func test___absent() {
        XCTAssertTrue(
            workerCapabilityConstraintResolver.requirementsSatisfied(
                requirements: [WorkerCapabilityRequirement(capabilityName: "name", constraint: .absent)],
                workerCapabilities: []
            )
        )
    }
    
    func test___not() {
        XCTAssertFalse(
            workerCapabilityConstraintResolver.requirementsSatisfied(
                requirements: [WorkerCapabilityRequirement(capabilityName: "name", constraint: .not(.absent))],
                workerCapabilities: []
            )
        )
    }
    
    func test___lessThan() {
        XCTAssertTrue(
            workerCapabilityConstraintResolver.requirementsSatisfied(
                requirements: [WorkerCapabilityRequirement(capabilityName: "name", constraint: .lessThan("10"))],
                workerCapabilities: [WorkerCapability(name: "name", value: "5")]
            )
        )
    }
    
    func test___greaterThan() {
        XCTAssertTrue(
            workerCapabilityConstraintResolver.requirementsSatisfied(
                requirements: [WorkerCapabilityRequirement(capabilityName: "name", constraint: .greaterThan("1"))],
                workerCapabilities: [WorkerCapability(name: "name", value: "5")]
            )
        )
    }
    
    func test___equal() {
        XCTAssertTrue(
            workerCapabilityConstraintResolver.requirementsSatisfied(
                requirements: [WorkerCapabilityRequirement(capabilityName: "name", constraint: .equal("value"))],
                workerCapabilities: [WorkerCapability(name: "name", value: "value")]
            )
        )
    }
    
    func test___all() {
        XCTAssertTrue(
            workerCapabilityConstraintResolver.requirementsSatisfied(
                requirements: [WorkerCapabilityRequirement(capabilityName: "name", constraint: .all([.not(.lessThan("5")), .not(.greaterThan("6"))]))],
                workerCapabilities: [WorkerCapability(name: "name", value: "5.5")]
            )
        )
    }
    
    func test___any() {
        XCTAssertFalse(
            workerCapabilityConstraintResolver.requirementsSatisfied(
                requirements: [WorkerCapabilityRequirement(capabilityName: "name", constraint: .any([.lessThan("5"), .greaterThan("6")]))],
                workerCapabilities: [WorkerCapability(name: "name", value: "5.5")]
            )
        )
    }
    
    func test___and() {
        XCTAssertFalse(
            workerCapabilityConstraintResolver.requirementsSatisfied(
                requirements: [WorkerCapabilityRequirement(capabilityName: "name", constraint: WorkerCapabilityConstraint.not(.equal("5")).and(.not(.equal("6"))))],
                workerCapabilities: [WorkerCapability(name: "name", value: "6")]
            )
        )
    }
    
    func test___or() {
        XCTAssertTrue(
            workerCapabilityConstraintResolver.requirementsSatisfied(
                requirements: [WorkerCapabilityRequirement(capabilityName: "name", constraint: WorkerCapabilityConstraint.equal("5").or(.equal("6")))],
                workerCapabilities: [WorkerCapability(name: "name", value: "6")]
            )
        )
    }
    
    func test___lessThanOrEqualTo() {
        let requirement = WorkerCapabilityRequirement(capabilityName: "name", constraint: .lessThanOrEqualTo("5"))
        XCTAssertFalse(
            workerCapabilityConstraintResolver.requirementsSatisfied(
                requirements: [requirement],
                workerCapabilities: [WorkerCapability(name: "name", value: "6")]
            )
        )
        XCTAssertTrue(
            workerCapabilityConstraintResolver.requirementsSatisfied(
                requirements: [requirement],
                workerCapabilities: [WorkerCapability(name: "name", value: "5")]
            )
        )
        XCTAssertTrue(
            workerCapabilityConstraintResolver.requirementsSatisfied(
                requirements: [requirement],
                workerCapabilities: [WorkerCapability(name: "name", value: "4")]
            )
        )
    }
    
    func test___greaterThanOrEqualTo() {
        let requirement = WorkerCapabilityRequirement(capabilityName: "name", constraint: .greaterThanOrEqualTo("5"))
        XCTAssertFalse(
            workerCapabilityConstraintResolver.requirementsSatisfied(
                requirements: [requirement],
                workerCapabilities: [WorkerCapability(name: "name", value: "4")]
            )
        )
        XCTAssertTrue(
            workerCapabilityConstraintResolver.requirementsSatisfied(
                requirements: [requirement],
                workerCapabilities: [WorkerCapability(name: "name", value: "5")]
            )
        )
        XCTAssertTrue(
            workerCapabilityConstraintResolver.requirementsSatisfied(
                requirements: [requirement],
                workerCapabilities: [WorkerCapability(name: "name", value: "6")]
            )
        )
    }
    
    func test___matching_multiple_capabilities_with_same_name() {
        XCTAssertTrue(
            workerCapabilityConstraintResolver.requirementsSatisfied(
                requirements: [WorkerCapabilityRequirement(capabilityName: "name", constraint: .equal("1"))],
                workerCapabilities: [
                    WorkerCapability(name: "name", value: "5"),
                    WorkerCapability(name: "name", value: "1"),
                ]
            )
        )
    }
}

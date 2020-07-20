import Models
import QueueCommunication
import QueueModels
import XCTest

class WorkersToUtilizeCalculatorTests: XCTestCase {
    private let calculator = DefaultWorkersToUtilizeCalculator()
    
    func test___disjoint___with_equal_number_of_workers_and_versions() {
        let initialWorkers = buildWorkers(count: 4)
        let initialMapping = buildMapping(versionsCount: 4, workers: initialWorkers)
        
        let mapping = calculator.disjointWorkers(mapping: initialMapping)
        let workers = mapping.values.flatMap { $0 }
        
        XCTAssertEqual(mapping["V1"]?.count, 1)
        XCTAssertEqual(mapping["V2"]?.count, 1)
        XCTAssertEqual(mapping["V3"]?.count, 1)
        XCTAssertEqual(mapping["V4"]?.count, 1)
        XCTAssertEqual(Set(workers), Set(initialWorkers))
    }
    
    func test___disjoint___with_less_versions_then_deployments() {
        let initialWorkers = buildWorkers(count: 4)
        let initialMapping = buildMapping(versionsCount: 2, workers: initialWorkers)
        
        let mapping = calculator.disjointWorkers(mapping: initialMapping)
        let workers = mapping.values.flatMap { $0 }
        
        XCTAssertEqual(mapping["V1"]?.count, 2)
        XCTAssertEqual(mapping["V2"]?.count, 2)
        XCTAssertEqual(Set(workers), Set(initialWorkers))
    }
    
    func test___disjoint___with_more_versions_then_deployments() {
        let initialWorkers = buildWorkers(count: 3)
        let initialMapping = buildMapping(versionsCount: 4, workers: initialWorkers)
        
        let mapping = calculator.disjointWorkers(mapping: initialMapping)
        let workers = mapping.values.flatMap { $0 }
        
        XCTAssertEqual(mapping["V1"]?.count, 1)
        XCTAssertEqual(mapping["V2"]?.count, 1)
        XCTAssertEqual(mapping["V3"]?.count, 1)
        XCTAssertEqual(mapping["V4"]?.count, 1)
        XCTAssertEqual(Set(workers), Set(initialWorkers))
    }
    
    func test___disjoint___with_only_one_version() {
        let initialWorkers = buildWorkers(count: 4)
        let initialMapping = buildMapping(versionsCount: 1, workers: initialWorkers)
        
        let mapping = calculator.disjointWorkers(mapping: initialMapping)
        let workers = mapping.values.flatMap { $0 }
        
        XCTAssertEqual(Set(workers), Set(initialWorkers))
    }
    
    func test___disjoint___with_dedicated_deployments() {
        let initialWorkers = buildWorkers(count: 4)
        var initialWorkersForV1 = initialWorkers
        initialWorkersForV1.append("WorkerId5")
        
        let initialMapping: WorkersPerVersion = [
            "V1": initialWorkersForV1,
            "V2": initialWorkers,
            "V3": initialWorkers,
            "V4": initialWorkers
        ]
        
        let mapping = calculator.disjointWorkers(mapping: initialMapping)
        let deployments = mapping["V2"]! + mapping["V3"]! + mapping["V4"]!
        
        XCTAssertEqual(mapping["V1"]?.count, 2)
        XCTAssertEqual(mapping["V2"]?.count, 1)
        XCTAssertEqual(mapping["V3"]?.count, 1)
        XCTAssertEqual(mapping["V4"]?.count, 1)
        XCTAssertEqual(Set(deployments).count, 3)
    }
    
    func test___disjoint___with_no_intersection() {
        let initialWorkers1: [WorkerId] = [
            "WorkerId1",
            "WorkerId2"
        ]
        let initialWorkers2: [WorkerId] = [
            "WorkerId3",
            "WorkerId4"
        ]
        let initialMapping: WorkersPerVersion = [
            "V1": initialWorkers1,
            "V2": initialWorkers2,
        ]
        
        let mapping = calculator.disjointWorkers(mapping: initialMapping)
        
        XCTAssertEqual(Set(mapping["V1"]!), Set(initialWorkers1))
        XCTAssertEqual(Set(mapping["V2"]!), Set(initialWorkers2))
    }
    
    func test___disjoint___with_mixed_deployments() {
        let worker1: WorkerId = "workerId1"
        let worker2: WorkerId = "workerId2"
        let worker3: WorkerId = "workerId3"
        let worker4: WorkerId = "workerId4"
        
        let workersForV1 = [worker1, worker2]
        let workersForV2 = [worker2, worker3]
        let workersForV3 = [worker3, worker4]
        let workersForV4 = [worker4, worker1]
        
        let initialMapping: WorkersPerVersion = [
            "V1": workersForV1,
            "V2": workersForV2,
            "V3": workersForV3,
            "V4": workersForV4
        ]
        
        let mapping = calculator.disjointWorkers(mapping: initialMapping)
        
        XCTAssertEqual(Set(mapping["V1"]!), Set(workersForV1))
        XCTAssertEqual(Set(mapping["V2"]!), Set(workersForV2))
        XCTAssertEqual(Set(mapping["V3"]!), Set(workersForV3))
        XCTAssertEqual(Set(mapping["V4"]!), Set(workersForV4))
    }
    
    func test___disjoint___implementation_imprint() {
        let initialWorkers = buildWorkers(count: 70)
        let initialMapping = buildMapping(versionsCount: 3, workers: initialWorkers)
        let expectedMapping: WorkersPerVersion = [
            "V1" : [
                "WorkerId01", "WorkerId04", "WorkerId07", "WorkerId10", "WorkerId13", "WorkerId16", "WorkerId19", "WorkerId22", "WorkerId25", "WorkerId28",
                "WorkerId31", "WorkerId34", "WorkerId37", "WorkerId40", "WorkerId43", "WorkerId46", "WorkerId49", "WorkerId52", "WorkerId55", "WorkerId58",
                "WorkerId61", "WorkerId64", "WorkerId67", "WorkerId70"
            ],
            "V2" : [
                "WorkerId02", "WorkerId05", "WorkerId08", "WorkerId11", "WorkerId14", "WorkerId17", "WorkerId20", "WorkerId23", "WorkerId26", "WorkerId29",
                "WorkerId32", "WorkerId35", "WorkerId38", "WorkerId41", "WorkerId44", "WorkerId47", "WorkerId50", "WorkerId53", "WorkerId56", "WorkerId59",
                "WorkerId62", "WorkerId65", "WorkerId68"
            ],
            "V3" : [
                "WorkerId03", "WorkerId06", "WorkerId09", "WorkerId12", "WorkerId15", "WorkerId18", "WorkerId21", "WorkerId24", "WorkerId27", "WorkerId30",
                "WorkerId33", "WorkerId36", "WorkerId39", "WorkerId42", "WorkerId45", "WorkerId48", "WorkerId51", "WorkerId54", "WorkerId57", "WorkerId60",
                "WorkerId63", "WorkerId66", "WorkerId69"
            ]
        ]
        
        let mapping = calculator.disjointWorkers(mapping: initialMapping)
        
        XCTAssertEqual(mapping, expectedMapping)
    }
    
    func test___disjoint___returns_same_set_of_workers_on_same_data() {
        let initialMapping1: WorkersPerVersion = [
            "V1": ["WorkerId1", "WorkerId2", "WorkerId3"],
            "V2": ["WorkerId1", "WorkerId2", "WorkerId3"],
            "V3": ["WorkerId1", "WorkerId2", "WorkerId3"],
        ]
        
        let initialMapping2: WorkersPerVersion = [
            "V3": ["WorkerId3", "WorkerId2", "WorkerId1"],
            "V1": ["WorkerId1", "WorkerId2", "WorkerId3"],
            "V2": ["WorkerId2", "WorkerId3", "WorkerId1"],
        ]
        
        let mapping1 = calculator.disjointWorkers(mapping: initialMapping1)
        let mapping2 = calculator.disjointWorkers(mapping: initialMapping2)
        
        XCTAssertEqual(mapping1, mapping2)
    }
    
    private func buildWorkers(count: Int) -> [WorkerId] {
        var workers = [WorkerId]()
        for i in 1...count {
            let prependedZero = i < 10 ? "0" : ""
            workers.append(WorkerId(value: "WorkerId\(prependedZero)\(i)"))
        }
        return workers
    }
    
    private func buildMapping(versionsCount: Int, workers: [WorkerId]) -> WorkersPerVersion {
        var mapping = WorkersPerVersion()
        for i in 1...versionsCount {
            mapping[Version(value: "V\(i)")] = workers
        }
        return mapping
    }
}

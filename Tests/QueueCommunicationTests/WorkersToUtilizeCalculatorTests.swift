@testable import QueueCommunication
import QueueModels
import SocketModels
import TestHelpers
import XCTest

class WorkersToUtilizeCalculatorTests: XCTestCase {
    private let calculator = DefaultWorkersToUtilizeCalculator(logger: .noOp)
    
    func test___when_number_of_queues_match_number_of_workers___splits_into_single_worker_per_queue() {
        let initialWorkers = buildWorkers(count: 4)
        let initialMapping = buildMapping(versionCount: 4, workers: initialWorkers)
        
        let mapping = calculator.disjointWorkers(mapping: initialMapping)
        let workers = mapping.flattenedWorkerIds
        
        XCTAssertEqual(mapping[buildQueueInfo(version: "V1")]?.count, 1)
        XCTAssertEqual(mapping[buildQueueInfo(version: "V2")]?.count, 1)
        XCTAssertEqual(mapping[buildQueueInfo(version: "V3")]?.count, 1)
        XCTAssertEqual(mapping[buildQueueInfo(version: "V4")]?.count, 1)
        XCTAssertEqual(Set(workers), Set(initialWorkers))
    }
    
    func test___when_number_of_queues_less_than_workers___splits_workers_evenly_per_queue() {
        let initialWorkers = buildWorkers(count: 4)
        let initialMapping = buildMapping(versionCount: 2, workers: initialWorkers)
        
        let mapping = calculator.disjointWorkers(mapping: initialMapping)
        let workers = mapping.flattenedWorkerIds
        
        XCTAssertEqual(mapping[buildQueueInfo(version: "V1")]?.count, 2)
        XCTAssertEqual(mapping[buildQueueInfo(version: "V2")]?.count, 2)
        XCTAssertEqual(Set(workers), initialWorkers)
    }
    
    func test___when_number_of_queues_more_than_workers___missing_worker_is_reused() {
        let initialWorkers = buildWorkers(count: 3)
        let initialMapping = buildMapping(versionCount: 4, workers: initialWorkers)
        
        let mapping = calculator.disjointWorkers(mapping: initialMapping)
        let workers = mapping.flattenedWorkerIds
        
        XCTAssertEqual(mapping[buildQueueInfo(version: "V1")]?.count, 1)
        XCTAssertEqual(mapping[buildQueueInfo(version: "V2")]?.count, 1)
        XCTAssertEqual(mapping[buildQueueInfo(version: "V3")]?.count, 1)
        XCTAssertEqual(mapping[buildQueueInfo(version: "V4")]?.count, 1)
        XCTAssertEqual(Set(workers), Set(initialWorkers))
    }
    
    func test___when_queue_is_single___all_workers_are_assigned_to_it() {
        let initialWorkers = buildWorkers(count: 4)
        let initialMapping = buildMapping(versionCount: 1, workers: initialWorkers)
        
        let mapping = calculator.disjointWorkers(mapping: initialMapping)
        let workers = mapping[buildQueueInfo(version: "V1")].flatMap { $0 }
        
        XCTAssertEqual(workers, Set(initialWorkers))
    }
    
    func test___when_queue_has_dedicated_worker_not_present_in_other_queues___it_is_assigned_to_that_queue() {
        let initialWorkers = buildWorkers(count: 4)
        
        var initialWorkersForV1 = initialWorkers
        initialWorkersForV1.insert("WorkerId5")
        
        let initialMapping: WorkersPerQueue = [
            buildQueueInfo(version: "V1"): initialWorkersForV1,
            buildQueueInfo(version: "V2"): initialWorkers,
            buildQueueInfo(version: "V3"): initialWorkers,
            buildQueueInfo(version: "V4"): initialWorkers
        ]
        
        let mapping = calculator.disjointWorkers(mapping: initialMapping)
        
        let workerIdsForQueuesWithVersionDifferentFromV1 = assertNotNil {
            mapping[buildQueueInfo(version: "V2")]
        }.union(
            assertNotNil { mapping[buildQueueInfo(version: "V3")] }
        ).union(
            assertNotNil { mapping[buildQueueInfo(version: "V4")] }
        )
        
        XCTAssertEqual(mapping[buildQueueInfo(version: "V1")]?.count, 2)
        XCTAssertEqual(mapping[buildQueueInfo(version: "V2")]?.count, 1)
        XCTAssertEqual(mapping[buildQueueInfo(version: "V3")]?.count, 1)
        XCTAssertEqual(mapping[buildQueueInfo(version: "V4")]?.count, 1)
        XCTAssertEqual(workerIdsForQueuesWithVersionDifferentFromV1.count, 3)
    }
    
    func test___when_queue_workers_do_not_intersect___disjoint_results_per_queue_also_do_not_intersect() {
        let initialWorkers1: Set<WorkerId> = [
            "WorkerId1",
            "WorkerId2"
        ]
        let initialWorkers2: Set<WorkerId> = [
            "WorkerId3",
            "WorkerId4"
        ]
        let initialMapping: WorkersPerQueue = [
            buildQueueInfo(version: "V1"): initialWorkers1,
            buildQueueInfo(version: "V2"): initialWorkers2,
        ]
        
        let mapping = calculator.disjointWorkers(mapping: initialMapping)
        
        XCTAssertEqual(mapping[buildQueueInfo(version: "V1")], initialWorkers1)
        XCTAssertEqual(mapping[buildQueueInfo(version: "V2")], initialWorkers2)
    }
    
    func test___when_queue_workers_intersect_complexly___workers_provided_back() {
        let worker1: WorkerId = "workerId1"
        let worker2: WorkerId = "workerId2"
        let worker3: WorkerId = "workerId3"
        let worker4: WorkerId = "workerId4"
        
        let workersForV1: Set<WorkerId> = [worker1, worker2]
        let workersForV2: Set<WorkerId> = [worker2, worker3]
        let workersForV3: Set<WorkerId> = [worker3, worker4]
        let workersForV4: Set<WorkerId> = [worker4, worker1]
        
        let initialMapping: WorkersPerQueue = [
            buildQueueInfo(version: "V1"): workersForV1,
            buildQueueInfo(version: "V2"): workersForV2,
            buildQueueInfo(version: "V3"): workersForV3,
            buildQueueInfo(version: "V4"): workersForV4
        ]
        
        let mapping = calculator.disjointWorkers(mapping: initialMapping)
        
        XCTAssertEqual(mapping[buildQueueInfo(version: "V1")], workersForV1)
        XCTAssertEqual(mapping[buildQueueInfo(version: "V2")], workersForV2)
        XCTAssertEqual(mapping[buildQueueInfo(version: "V3")], workersForV3)
        XCTAssertEqual(mapping[buildQueueInfo(version: "V4")], workersForV4)
    }
    
    func test___disjoint___implementation_imprint() {
        let initialWorkers = buildWorkers(count: 70)
        let initialMapping = buildMapping(versionCount: 3, workers: initialWorkers)
        let expectedMapping: WorkersPerQueue = [
            buildQueueInfo(version: "V1") : [
                "WorkerId01", "WorkerId04", "WorkerId07", "WorkerId10", "WorkerId13", "WorkerId16", "WorkerId19", "WorkerId22", "WorkerId25", "WorkerId28",
                "WorkerId31", "WorkerId34", "WorkerId37", "WorkerId40", "WorkerId43", "WorkerId46", "WorkerId49", "WorkerId52", "WorkerId55", "WorkerId58",
                "WorkerId61", "WorkerId64", "WorkerId67", "WorkerId70"
            ],
            buildQueueInfo(version: "V2") : [
                "WorkerId02", "WorkerId05", "WorkerId08", "WorkerId11", "WorkerId14", "WorkerId17", "WorkerId20", "WorkerId23", "WorkerId26", "WorkerId29",
                "WorkerId32", "WorkerId35", "WorkerId38", "WorkerId41", "WorkerId44", "WorkerId47", "WorkerId50", "WorkerId53", "WorkerId56", "WorkerId59",
                "WorkerId62", "WorkerId65", "WorkerId68"
            ],
            buildQueueInfo(version: "V3") : [
                "WorkerId03", "WorkerId06", "WorkerId09", "WorkerId12", "WorkerId15", "WorkerId18", "WorkerId21", "WorkerId24", "WorkerId27", "WorkerId30",
                "WorkerId33", "WorkerId36", "WorkerId39", "WorkerId42", "WorkerId45", "WorkerId48", "WorkerId51", "WorkerId54", "WorkerId57", "WorkerId60",
                "WorkerId63", "WorkerId66", "WorkerId69"
            ]
        ]
        
        let mapping = calculator.disjointWorkers(mapping: initialMapping)
        
        XCTAssertEqual(mapping, expectedMapping)
    }
    
    func test___disjoint___returns_same_set_of_workers_on_same_data() {
        let initialMapping1: WorkersPerQueue = [
            buildQueueInfo(version: "V1"): ["WorkerId1", "WorkerId2", "WorkerId3"],
            buildQueueInfo(version: "V2"): ["WorkerId1", "WorkerId2", "WorkerId3"],
            buildQueueInfo(version: "V3"): ["WorkerId1", "WorkerId2", "WorkerId3"],
        ]
        
        let initialMapping2: WorkersPerQueue = [
            buildQueueInfo(version: "V3"): ["WorkerId3", "WorkerId2", "WorkerId1"],
            buildQueueInfo(version: "V1"): ["WorkerId1", "WorkerId2", "WorkerId3"],
            buildQueueInfo(version: "V2"): ["WorkerId2", "WorkerId3", "WorkerId1"],
        ]
        
        let mapping1 = calculator.disjointWorkers(mapping: initialMapping1)
        let mapping2 = calculator.disjointWorkers(mapping: initialMapping2)
        
        XCTAssertEqual(mapping1, mapping2)
    }
    
    func test___disjoint_on_multiple_hosts_with_same_version() {
        let version: Version = "Version"
        let initialWorkers = buildWorkers(count: 15)
        
        let initialMapping: WorkersPerQueue = [
            buildQueueInfo(host: "host1", port: 42, version: version): initialWorkers,
            buildQueueInfo(host: "host2", port: 41, version: version): initialWorkers,
            buildQueueInfo(host: "host3", port: 40, version: version): initialWorkers,
        ]
        
        let expectedMapping: WorkersPerQueue = [
            buildQueueInfo(host: "host1", port: 42, version: version): [
                "WorkerId01", "WorkerId04", "WorkerId07", "WorkerId10", "WorkerId13",
            ],
            buildQueueInfo(host: "host2", port: 41, version: version): [
                "WorkerId02", "WorkerId05", "WorkerId08", "WorkerId11", "WorkerId14",
            ],
            buildQueueInfo(host: "host3", port: 40, version: version): [
                "WorkerId03", "WorkerId06", "WorkerId09", "WorkerId12", "WorkerId15",
            ],
        ]
        
        let mapping = calculator.disjointWorkers(mapping: initialMapping)
        assert { mapping } equals: { expectedMapping }
    }

    private func buildWorkers(count: Int) -> Set<WorkerId> {
        var workers = Set<WorkerId>()
        for i in 1...count {
            let prependedZero = i < 10 ? "0" : ""
            workers.insert(WorkerId(value: "WorkerId\(prependedZero)\(i)"))
        }
        return workers
    }
    
    private func buildMapping(versionCount: Int, workers: Set<WorkerId>) -> WorkersPerQueue {
        let mapping = WorkersPerQueue()
        for i in 1...versionCount {
            mapping[buildQueueInfo(version: Version("V\(i)"))] = workers
        }
        return mapping
    }
    
    private func buildQueueInfo(
        host: String = "host",
        port: SocketModels.Port = 42,
        version: Version
    ) -> QueueInfo {
        QueueInfo(
            queueAddress: SocketAddress(
                host: host,
                port: port
            ),
            queueVersion: version
        )
    }
}

extension WorkersPerQueue {
    var flattenedWorkerIds: Set<WorkerId> {
        Set(workersByQueueInfo.values.flatMap {
            $0
        })
    }
}

import QueueCommunication
import QueueCommunicationTestHelpers
import QueueModels
import RemotePortDeterminerTestHelpers
import SocketModels
import XCTest

class WorkersToUtilizeServiceTests: XCTestCase {
    private let cache = FakeWorkersMappingCache()
    private let calculator = FakeWorkersToUtilizeCalculator()
    private let communicationService = FakeQueueCommunicationService()
    
    
    func test___workersToUtilize___returns_cached_workers___if_cache_avaliable() {
        let service = buildService()
        let expectedWorkerIds: [WorkerId] = ["WorkerId"]
        cache.presetCachedMapping = ["Version": expectedWorkerIds]
        
        let workers = service.workersToUtilize(initialWorkers: [], version: "Version")
        
        XCTAssertEqual(workers, expectedWorkerIds )
    }
    
    func test___workersToUtilize___succesfull_scenario() {
        let expectedWorkersBerforeCalculation: [WorkerId] = ["WorkerId1", "WorkerId2"]
        communicationService.workersPerPort = [100: expectedWorkersBerforeCalculation]
        let service = buildService(ports: [100 : "Version"])
        let expectedWorkersAfterCalculation: [WorkerId] = ["WorkerId1"]
        let calculationResult: WorkersPerVersion = ["Version": expectedWorkersAfterCalculation]
        calculator.result = calculationResult
        
        let workers = service.workersToUtilize(initialWorkers: [], version: "Version")
        
        XCTAssertEqual(calculator.receivedMapping, ["Version": expectedWorkersBerforeCalculation])
        XCTAssertEqual(workers, expectedWorkersAfterCalculation)
        XCTAssertEqual(cache.cacheMappingArgument, calculationResult)
    }
    
    func test___workersToUtilize___returns_default_workers___if_calculation_is_corrupted() {
        communicationService.workersPerPort = [100: ["WorkerId1", "WorkerId2"]]
        let service = buildService(ports: [100 : "Version"])
        calculator.result = ["CorruptedVersion": ["CurruptedWorkerId"]]
        let initialWorkers: [WorkerId] = ["InitialWorkerId1", "InitialWorkerId2"]
        
        let workers = service.workersToUtilize(initialWorkers: initialWorkers, version: "Version")
        
        XCTAssertEqual(workers, initialWorkers)
    }
    
    func test___workersToUtilize___calls_workers_to_utilize_for_all_available_ports() {
        let service = buildService(ports: [
            100 : "Version1",
            101 : "Version2",
            102 : "Version3",
        ])
        
        _ = service.workersToUtilize(initialWorkers: [], version: "Version")
        
        XCTAssertEqual(Set(communicationService.deploymentDestinationsCallPorts), Set([100, 101, 102]))
    }
    
    func test___workersToUtilize___composes_workers_from_all_available_queues() {
        let version1workers: [WorkerId] = ["WorkerId1", "WorkerId2"]
        let version2workers: [WorkerId] = ["WorkerId3", "WorkerId4"]
        let version3workers: [WorkerId] = ["WorkerId5", "WorkerId6"]
        communicationService.workersPerPort = [
            101: version1workers,
            102: version2workers,
            103: version3workers,
        ]
        let service = buildService(ports: [
            101 : "Version1",
            102 : "Version2",
            103 : "Version3"
        ])
        let expectedMapping: WorkersPerVersion = [
            "Version1": version1workers,
            "Version2": version2workers,
            "Version3": version3workers
        ]
        
        _ = service.workersToUtilize(initialWorkers: [], version: "Version")
        
        XCTAssertEqual(calculator.receivedMapping, expectedMapping)
    }
    
    func test___workersToUtilize___wait_for_async_answer() {
        communicationService.deploymentDestinationsAsync = true
        let version1workers: [WorkerId] = ["WorkerId1", "WorkerId2"]
        let version2workers: [WorkerId] = ["WorkerId3", "WorkerId4"]
        let version3workers: [WorkerId] = ["WorkerId5", "WorkerId6"]
        communicationService.workersPerPort = [
            101: version1workers,
            102: version2workers,
            103: version3workers,
        ]
        let service = buildService(ports: [
            101 : "Version1",
            102 : "Version2",
            103 : "Version3"
        ])
        let expectedMapping: WorkersPerVersion = [
            "Version1": version1workers,
            "Version2": version2workers,
            "Version3": version3workers
        ]
        
        _ = service.workersToUtilize(initialWorkers: [], version: "Version")
        
        XCTAssertEqual(calculator.receivedMapping, expectedMapping)
    }
    
    private func buildService(
        ports: [SocketModels.Port: Version] = [:],
        workersPerPort: [SocketModels.Port: [WorkerId]] = [:]
    ) -> WorkersToUtilizeService {
        return DefaultWorkersToUtilizeService(
            cache: cache,
            calculator: calculator,
            communicationService: communicationService,
            portDeterminer: RemotePortDeterminerFixture(result: ports).build()
        )
    }
}

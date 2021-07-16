import QueueCommunication
import QueueCommunicationTestHelpers
import QueueModels
import RemotePortDeterminerTestHelpers
import SocketModels
import TestHelpers
import XCTest

final class WorkersToUtilizeServiceTests: XCTestCase {
    private let cache = FakeWorkersMappingCache()
    private let calculator = FakeWorkersToUtilizeCalculator()
    private let communicationService = FakeQueueCommunicationService()
    private lazy var queueAddress = SocketAddress(host: "host", port: 100)
    private lazy var queueVersion = Version("Version")
    private lazy var queueInfo = QueueInfo(queueAddress: queueAddress, queueVersion: queueVersion)

    func test___workersToUtilize___returns_cached_workers___if_cache_avaliable() {
        let service = buildService()
        let expectedWorkerIds: Set<WorkerId> = ["WorkerId"]

        cache.presetCachedMapping = [
            queueInfo: expectedWorkerIds
        ]

        let workers = service.workersToUtilize(initialWorkerIds: [], queueInfo: queueInfo)

        XCTAssertEqual(workers, expectedWorkerIds)
    }

    func test___workersToUtilize___succesfull_scenario() {
        let expectedWorkersBerforeCalculation: Set<WorkerId> = ["WorkerId1", "WorkerId2"]
        communicationService.workersPerSocketAddress = [
            queueInfo.queueAddress: expectedWorkersBerforeCalculation
        ]

        let service = buildService(
            sockets: [
                queueInfo.queueAddress: queueVersion
            ]
        )
        let expectedWorkersAfterCalculation: Set<WorkerId> = [
            "WorkerId1",
        ]
        let calculationResult: WorkersPerQueue = [queueInfo: expectedWorkersAfterCalculation]

        calculator.result = calculationResult

        let workers = service.workersToUtilize(initialWorkerIds: [], queueInfo: queueInfo)

        assert { calculator.receivedMapping } equals: {
            [queueInfo: expectedWorkersBerforeCalculation]
        }
        assert { workers } equals: { expectedWorkersAfterCalculation }
        assert { cache.cacheMappingArgument } equals: { calculationResult }
    }

    func test___workersToUtilize___returns_default_workers___if_queue_info_is_unknown() {
        // Notice: service uses port scanner to locate all surrounding queues.
        // In this test, we simulate that port scanner is not aware of some queue,
        // because it wasn't configured to search at 'other' host.
        //
        // Current behaviour: we just return initial set of worker ids back to the
        // queue which came from unexpected/unknown host.
        //
        // Possible improvement: port scanner may adopt itself and start scanning
        // for running queues at previosly unknown hosts.
        
        communicationService.workersPerSocketAddress = [
            queueAddress: ["WorkerId1", "WorkerId2"]
        ]
        let service = buildService(sockets: [
            queueAddress: queueVersion
        ])

        calculator.result = [
            QueueInfo(
                queueAddress: SocketAddress(host: "other", port: 999),
                queueVersion: "OtherVersion"
            ): ["CurruptedWorkerId"]
        ]
        let initialWorkerIds: Set<WorkerId> = ["InitialWorkerId1", "InitialWorkerId2"]
        
        assert {
            service.workersToUtilize(initialWorkerIds: initialWorkerIds, queueInfo: queueInfo)
        } equals: {
            initialWorkerIds
        }
    }

    func test___workersToUtilize___calls_workers_to_utilize_on_all_known_queue_addresses() {
        let service = buildService(sockets: [
            SocketAddress(host: "host", port: 100): "Version1",
            SocketAddress(host: "host", port: 101): "Version2",
            SocketAddress(host: "host", port: 102): "Version3",
        ])

        _ = service.workersToUtilize(initialWorkerIds: [], queueInfo: queueInfo)

        XCTAssertEqual(
            Set(communicationService.allQueriedQueueAddresses),
            Set([
                SocketAddress(host: "host", port: 100),
                SocketAddress(host: "host", port: 101),
                SocketAddress(host: "host", port: 102),
            ])
        )
    }

    func test___workersToUtilize___composes_workers_from_all_available_queues() {
        let version1workers: Set<WorkerId> = ["WorkerId1", "WorkerId2"]
        let version2workers: Set<WorkerId> = ["WorkerId3", "WorkerId4"]
        let version3workers: Set<WorkerId> = ["WorkerId5", "WorkerId6"]
        
        let queueInfos = [
            QueueInfo(queueAddress: SocketAddress(host: "host", port: 101), queueVersion: "Version1"),
            QueueInfo(queueAddress: SocketAddress(host: "host", port: 102), queueVersion: "Version2"),
            QueueInfo(queueAddress: SocketAddress(host: "host", port: 103), queueVersion: "Version3"),
        ]
        
        communicationService.workersPerSocketAddress = [
            queueInfos[0].queueAddress: version1workers,
            queueInfos[1].queueAddress: version2workers,
            queueInfos[2].queueAddress: version3workers,
        ]
        
        let service = buildService(sockets: [
            queueInfos[0].queueAddress: queueInfos[0].queueVersion,
            queueInfos[1].queueAddress: queueInfos[1].queueVersion,
            queueInfos[2].queueAddress: queueInfos[2].queueVersion,
        ])
        let expectedMapping: WorkersPerQueue = [
            queueInfos[0]: version1workers,
            queueInfos[1]: version2workers,
            queueInfos[2]: version3workers
        ]

        _ = service.workersToUtilize(initialWorkerIds: [], queueInfo: queueInfo)

        assert { calculator.receivedMapping } equals: { expectedMapping }
    }

    func test___workersToUtilize___waits_for_async_answer() {
        communicationService.deploymentDestinationsAsync = true
        let version1workers: Set<WorkerId> = ["WorkerId1", "WorkerId2"]
        let version2workers: Set<WorkerId> = ["WorkerId3", "WorkerId4"]
        let version3workers: Set<WorkerId> = ["WorkerId5", "WorkerId6"]

        let queueInfos = [
            QueueInfo(queueAddress: SocketAddress(host: "host", port: 101), queueVersion: "Version1"),
            QueueInfo(queueAddress: SocketAddress(host: "host", port: 102), queueVersion: "Version2"),
            QueueInfo(queueAddress: SocketAddress(host: "host", port: 103), queueVersion: "Version3"),
        ]
        
        communicationService.workersPerSocketAddress = [
            queueInfos[0].queueAddress: version1workers,
            queueInfos[1].queueAddress: version2workers,
            queueInfos[2].queueAddress: version3workers,
        ]
        let service = buildService(sockets: [
            queueInfos[0].queueAddress: queueInfos[0].queueVersion,
            queueInfos[1].queueAddress: queueInfos[1].queueVersion,
            queueInfos[2].queueAddress: queueInfos[2].queueVersion,
        ])
        let expectedMapping: WorkersPerQueue = [
            queueInfos[0]: version1workers,
            queueInfos[1]: version2workers,
            queueInfos[2]: version3workers
        ]

        _ = service.workersToUtilize(initialWorkerIds: [], queueInfo: queueInfo)

        assert { calculator.receivedMapping } equals: { expectedMapping }
    }

    private func buildService(
        sockets: [SocketAddress: Version] = [:]
    ) -> WorkersToUtilizeService {
        return DefaultWorkersToUtilizeService(
            cache: cache,
            calculator: calculator,
            communicationService: communicationService,
            logger: .noOp,
            portDeterminer: RemotePortDeterminerFixture(result: sockets).build()
        )
    }
}

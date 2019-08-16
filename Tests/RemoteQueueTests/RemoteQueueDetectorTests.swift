import Foundation
import RemoteQueue
import RemotePortDeterminerTestHelpers
import Version
import VersionTestHelpers
import XCTest

final class RemoteQueueDetectorTests: XCTestCase {
    let localQueueVersionProvider = VersionProviderFixture()
        .with(predefinedVersion: "local_version")
        .buildVersionProvider()
    
    func test___when_no_queues_running___returns_empty_result() {
        let remotePortDeterminer = RemotePortDeterminerFixture().build()
        
        let detector = RemoteQueueDetector(
            localQueueClientVersionProvider: localQueueVersionProvider,
            remotePortDeterminer: remotePortDeterminer
        )
        
        XCTAssertEqual(
            try detector.findSuitableRemoteRunningQueuePorts(timeout: 10.0),
            []
        )
    }
    
    func test___when_no_matching_queue_running___returns_empty_result() {
        let remotePortDeterminer = RemotePortDeterminerFixture(result: [42: Version(value: "remote_version")])
            .build()
        
        let detector = RemoteQueueDetector(
            localQueueClientVersionProvider: localQueueVersionProvider,
            remotePortDeterminer: remotePortDeterminer
        )
        
        XCTAssertEqual(
            try detector.findSuitableRemoteRunningQueuePorts(timeout: 10.0),
            []
        )
    }
    
    func test___when_matching_queue_is_running___returns_correct_result() {
        let remotePortDeterminer = RemotePortDeterminerFixture()
            .set(port: 42, version: Version(value: "local_version"))
            .set(port: 43, version: Version(value: "_version"))
            .set(port: 44, version: Version(value: "local_version"))
            .build()
        
        let detector = RemoteQueueDetector(
            localQueueClientVersionProvider: localQueueVersionProvider,
            remotePortDeterminer: remotePortDeterminer
        )
        
        XCTAssertEqual(
            try detector.findSuitableRemoteRunningQueuePorts(timeout: 10.0),
            [42, 44]
        )
    }
}


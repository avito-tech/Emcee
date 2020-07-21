import Foundation
import QueueCommunication
import QueueModels
import RemotePortDeterminerTestHelpers
import XCTest

final class RemoteQueueDetectorTests: XCTestCase {
    func test___findSuitableRemoteRunningQueuePorts___when_no_queues_running___returns_empty_result() {
        let remotePortDeterminer = RemotePortDeterminerFixture().build()
        
        let detector = DefaultRemoteQueueDetector(
            emceeVersion: "local_version",
            remotePortDeterminer: remotePortDeterminer
        )
        
        XCTAssertEqual(
            try detector.findSuitableRemoteRunningQueuePorts(timeout: 10.0),
            []
        )
    }
    
    func test___findSuitableRemoteRunningQueuePorts___when_no_matching_queue_running___returns_empty_result() {
        let remotePortDeterminer = RemotePortDeterminerFixture(result: [42: Version(value: "remote_version")])
            .build()
        
        let detector = DefaultRemoteQueueDetector(
            emceeVersion: "local_version",
            remotePortDeterminer: remotePortDeterminer
        )
        
        XCTAssertEqual(
            try detector.findSuitableRemoteRunningQueuePorts(timeout: 10.0),
            []
        )
    }
    
    func test___findSuitableRemoteRunningQueuePorts___when_matching_queue_is_running___returns_correct_result() {
        let remotePortDeterminer = RemotePortDeterminerFixture()
            .set(port: 42, version: Version(value: "local_version"))
            .set(port: 43, version: Version(value: "_version"))
            .set(port: 44, version: Version(value: "local_version"))
            .build()
        
        let detector = DefaultRemoteQueueDetector(
            emceeVersion: "local_version",
            remotePortDeterminer: remotePortDeterminer
        )
        
        XCTAssertEqual(
            try detector.findSuitableRemoteRunningQueuePorts(timeout: 10.0),
            [42, 44]
        )
    }
    
    func test___findMasterQueuePort___when_no_queues_running___throws() {
        let remotePortDeterminer = RemotePortDeterminerFixture().build()
        
        let detector = DefaultRemoteQueueDetector(
            emceeVersion: "local_version",
            remotePortDeterminer: remotePortDeterminer
        )
        
        XCTAssertThrowsError(try detector.findMasterQueuePort(timeout: 10))
    }
    
    func test___findMasterQueuePort___with_one_local_queue_running() {
        let remotePortDeterminer = RemotePortDeterminerFixture()
            .set(port: 42, version: Version(value: "local_version"))
            .build()
        
        
        let detector = DefaultRemoteQueueDetector(
            emceeVersion: "local_version",
            remotePortDeterminer: remotePortDeterminer
        )
        
        XCTAssertEqual(try detector.findMasterQueuePort(timeout: 10), 42)
    }
    
    func test___findMasterQueuePort___with_one_remote_queue_running() {
        let remotePortDeterminer = RemotePortDeterminerFixture()
            .set(port: 42, version: Version(value: "remote_version"))
            .build()
        
        
        let detector = DefaultRemoteQueueDetector(
            emceeVersion: "local_version",
            remotePortDeterminer: remotePortDeterminer
        )
        
        XCTAssertEqual(try detector.findMasterQueuePort(timeout: 10), 42)
    }
    
    func test___findMasterQueuePort___with_many_queues_running_lexicographical_order() {
        let remotePortDeterminer = RemotePortDeterminerFixture()
            .set(port: 42, version: Version(value: "version1"))
            .set(port: 43, version: Version(value: "version2"))
            .set(port: 44, version: Version(value: "version3"))
            .build()
        
        
        let detector = DefaultRemoteQueueDetector(
            emceeVersion: "version1",
            remotePortDeterminer: remotePortDeterminer
        )
        
        XCTAssertEqual(try detector.findMasterQueuePort(timeout: 10), 44)
    }
    
    func test___findMasterQueuePort___with_many_queues_running_length_order() {
        let remotePortDeterminer = RemotePortDeterminerFixture()
            .set(port: 42, version: Version(value: "version111"))
            .set(port: 43, version: Version(value: "version11"))
            .set(port: 44, version: Version(value: "version1"))
            .build()
        
        
        let detector = DefaultRemoteQueueDetector(
            emceeVersion: "version1",
            remotePortDeterminer: remotePortDeterminer
        )
        
        XCTAssertEqual(try detector.findMasterQueuePort(timeout: 10), 42)
    }
}


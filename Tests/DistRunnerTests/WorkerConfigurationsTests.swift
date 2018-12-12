import Foundation
import DistRunner
import Models
import ModelsTestHelpers
import XCTest

final class WorkerConfigurationsTests: XCTestCase {
    func test__if_worker_is_unknown__configuration_is_nil() {
        let configurations = WorkerConfigurations()
        XCTAssertNil(configurations.workerConfiguration(workerId: "worker"))
    }
    
    func test__if_worker_unknown__configuration_is_expected() {
        let config = WorkerConfigurationFixtures.workerConfiguration
        
        let configurations = WorkerConfigurations()
        configurations.add(workerId: "some_worker", configuration: config)
        XCTAssertEqual(configurations.workerConfiguration(workerId: "some_worker"), config)
    }
}

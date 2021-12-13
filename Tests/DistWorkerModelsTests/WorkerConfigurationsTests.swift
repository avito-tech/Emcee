import DistWorkerModels
import DistWorkerModelsTestHelpers
import Foundation
import XCTest

final class FixedWorkerConfigurationsTests: XCTestCase {
    lazy var configurations = FixedWorkerConfigurations()

    func test__if_worker_is_unknown__configuration_is_nil() {
        XCTAssertNil(configurations.workerConfiguration(workerId: "worker"))
    }
    
    func test__if_worker_unknown__configuration_is_expected() {
        let config = WorkerConfigurationFixtures.workerConfiguration
        
        configurations.add(workerId: "some_worker", configuration: config)
        
        XCTAssertEqual(configurations.workerConfiguration(workerId: "some_worker"), config)
    }
}

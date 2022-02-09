import Foundation
import TestDestination
import TestHelpers
import SimulatorPoolModels
import XCTest

final class TestDestination_AppleCreationTests: XCTestCase {
    func test__creating_from_json___old_style() throws {
        let decoder = JSONDecoder()
        let jsonData = Data("{\"deviceType\": \"iPhone SE\", \"runtime\": \"15.0\"}".utf8)
        let testDestination = try decoder.decode(TestDestination.self, from: jsonData)
        
        assert {
            try testDestination.simDeviceType()
        } equals: {
            SimDeviceType(fullyQualifiedId: "com.apple.CoreSimulator.SimDeviceType.iPhone-SE")
        }
        
        assert {
            try testDestination.simRuntime()
        } equals: {
            SimRuntime(fullyQualifiedId: "com.apple.CoreSimulator.SimRuntime.iOS-15-0")
        }
    }
    
    func test__creating_from_json___modern_style() {
        let decoder = JSONDecoder()
        let jsonData = Data("{\"simDeviceType\": \"com.apple.CoreSimulator.SimDeviceType.iPhone-SE\", \"simRuntime\": \"com.apple.CoreSimulator.SimRuntime.iOS-15-0\"}".utf8)
        assert {
            try decoder.decode(TestDestination.self, from: jsonData)
        } equals: {
            TestDestination.iOSSimulator(
                deviceType: "iPhone SE",
                version: "15.0"
            )
        }
    }
    
    func test___metric_properties() {
        let destination = TestDestination.appleSimulator(deviceType: "iPhone X", kind: .iOS, version: "15.0")
        
        assert { try destination.simDeviceType().shortForMetrics } equals: { "iPhone_X" }
        assert { try destination.simRuntime().shortForMetrics } equals: { "iOS_15_0" }
    }
    
    func test___creating_with_human_input() {
        let destination = TestDestination.appleSimulator(deviceType: "iPhone X", kind: .iOS, version: "15.0")
        
        assert { try destination.simDeviceType().fullyQualifiedId } equals: { "com.apple.CoreSimulator.SimDeviceType.iPhone-X" }
        assert { try destination.simRuntime().fullyQualifiedId } equals: { "com.apple.CoreSimulator.SimRuntime.iOS-15-0" }
    }
}

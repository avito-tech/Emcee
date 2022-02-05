import Foundation
import TestDestination
import TestHelpers
import XCTest

final class AppleTestDestinationTests: XCTestCase {
    func test__creating_from_json___old_style() {
        let decoder = JSONDecoder()
        let jsonData = Data("{\"deviceType\": \"iPhone SE\", \"runtime\": \"11.3\"}".utf8)
        assert {
            try decoder.decode(AppleTestDestination.self, from: jsonData)
        } equals: {
            AppleTestDestination.iOSSimulator(
                deviceType: "iPhone SE",
                version: "11.3"
            )
        }
    }
    
    func test__creating_from_json___modern_style() {
        let decoder = JSONDecoder()
        let jsonData = Data("{\"simDeviceType\": \"com.apple.CoreSimulator.SimDeviceType.iPhone-SE\", \"simRuntime\": \"com.apple.CoreSimulator.SimRuntime.iOS-15-0\"}".utf8)
        assert {
            try decoder.decode(AppleTestDestination.self, from: jsonData)
        } equals: {
            AppleTestDestination.iOSSimulator(
                deviceType: "iPhone SE",
                version: "15.0"
            )
        }
    }
    
    func test___metric_properties() {
        let destination = AppleTestDestination.appleSimulator(deviceType: "iPhone X", kind: .iOS, version: "15.0")
        
        assert { destination.deviceTypeForMetrics } equals: { "iPhone_X" }
        assert { destination.runtimeForMetrics } equals: { "iOS_15_0" }
    }
    
    func test___creating_with_human_input() {
        let destination = AppleTestDestination.appleSimulator(deviceType: "iPhone X", kind: .iOS, version: "15.0")
        
        assert { destination.simRuntime } equals: { "com.apple.CoreSimulator.SimRuntime.iOS-15-0" }
        assert { destination.simDeviceType } equals: { "com.apple.CoreSimulator.SimDeviceType.iPhone-X" }
    }
}

import Foundation
import TestHelpers
import WorkerCapabilities
import WorkerCapabilitiesModels
import XCTest

final class OperatingSystemCapabilitiesProviderTests: XCTestCase {
    func test() {
        let provider = OperatingSystemCapabilitiesProvider(
            operatingSystemVersionProvider: OperatingSystemVersion(
                majorVersion: 1,
                minorVersion: 2,
                patchVersion: 3
            )
        )
        
        assert {
            provider.workerCapabilities()
        } equals: {
            Set([
                WorkerCapability(name: OperatingSystemCapabilitiesProvider.workerCapabilityName(component: .major), value: "1"),
                WorkerCapability(name: OperatingSystemCapabilitiesProvider.workerCapabilityName(component: .minor), value: "2"),
                WorkerCapability(name: OperatingSystemCapabilitiesProvider.workerCapabilityName(component: .patch), value: "3"),
            ])
        }
    }
}

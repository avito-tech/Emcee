import Foundation
import WorkerCapabilitiesModels

public final class OperatingSystemCapabilitiesProvider: WorkerCapabilitiesProvider {
    private let operatingSystemVersionProvider: OperatingSystemVersionProvider
    
    public init(operatingSystemVersionProvider: OperatingSystemVersionProvider) {
        self.operatingSystemVersionProvider = operatingSystemVersionProvider
    }
    
    public enum SemVerComponent: String {
        case major
        case minor
        case patch
    }
    
    public static func workerCapabilityName(component: SemVerComponent) -> WorkerCapabilityName {
        WorkerCapabilityName("emcee.os.version.\(component.rawValue)")
    }
    
    public func workerCapabilities() -> Set<WorkerCapability> {
        let version = operatingSystemVersionProvider.operatingSystemVersion
        
        return [
            WorkerCapability(name: Self.workerCapabilityName(component: .major), value: "\(version.majorVersion)"),
            WorkerCapability(name: Self.workerCapabilityName(component: .minor), value: "\(version.minorVersion)"),
            WorkerCapability(name: Self.workerCapabilityName(component: .patch), value: "\(version.patchVersion)"),
        ]
    }
}

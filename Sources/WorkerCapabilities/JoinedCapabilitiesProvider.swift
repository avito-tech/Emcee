import Foundation
import WorkerCapabilitiesModels

public final class JoinedCapabilitiesProvider: WorkerCapabilitiesProvider {
    private let providers: [WorkerCapabilitiesProvider]
    
    public init(providers: [WorkerCapabilitiesProvider]) {
        self.providers = providers
    }
    
    public func workerCapabilities() -> Set<WorkerCapability> {
        Set(providers.flatMap { $0.workerCapabilities() })
    }
}

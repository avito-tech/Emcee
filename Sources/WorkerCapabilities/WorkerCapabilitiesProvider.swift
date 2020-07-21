import Foundation
import WorkerCapabilitiesModels

public protocol WorkerCapabilitiesProvider {
    func workerCapabilities() -> Set<WorkerCapability>
}

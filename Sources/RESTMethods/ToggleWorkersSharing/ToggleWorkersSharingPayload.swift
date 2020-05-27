public enum WorkersSharingFeatureStatus: String, Codable {
    case enabled
    case disabled
}

public final class ToggleWorkersSharingPayload: Codable {
    public let status: WorkersSharingFeatureStatus
    
    public init(status: WorkersSharingFeatureStatus) {
        self.status = status
    }
}

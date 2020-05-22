import Models

public protocol WorkersSharingToggler {
    func setSharingStatus(_ status: WorkersSharingFeatureStatus) throws
}

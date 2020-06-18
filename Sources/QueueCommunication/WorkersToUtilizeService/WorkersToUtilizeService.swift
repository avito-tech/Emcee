import Models

public protocol WorkersToUtilizeService {
    func workersToUtilize(initialWorkers: [WorkerId], version: Version) -> [WorkerId]
}

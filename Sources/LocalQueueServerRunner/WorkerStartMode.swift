import Foundation

public enum WorkerStartMode: String, Codable, Hashable, CustomStringConvertible {
    /// Queue will start all its workers. It will SSH onto worker machine and use launchd to start worker daemon.
    case queueStartsItsWorkersOverSshAndLaunchd
    
    /// Queue workers will be started by some other force (e.g. manually)
    case unknownWayOfStartingWorkers
    
    public var description: String { rawValue }
}


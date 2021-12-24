import AutomaticTermination
import Foundation
import QueueModels

public enum QueueServerConfigurationDefaultValues {
    public static let checkAgainTimeInterval: TimeInterval = 30
    public static let queueServerTerminationPolicy: AutomaticTerminationPolicy = .stayAlive
    public static let defaultWorkerConfiguration: WorkerSpecificConfiguration = WorkerSpecificConfiguration(numberOfSimulators: 3)
    public static let workerSpecificConfigurations: [String: WorkerSpecificConfiguration] = [:]
    public static let workerStartMode: WorkerStartMode = .queueStartsItsWorkersOverSshAndLaunchd
    public static let useOnlyIPv4: Bool = true
}

import MetricsExtensions
import QueueModels
import Tmp

public protocol RunnerProvider {
    associatedtype T: Runner
    
    func create(
        specificMetricRecorder: SpecificMetricRecorder,
        tempFolder: TemporaryFolder,
        version: Version
    ) -> T
}

import MetricsExtensions
import QueueModels
import Tmp

public protocol RunnerProvider {
    func create(
        specificMetricRecorder: SpecificMetricRecorder,
        tempFolder: TemporaryFolder,
        version: Version
    ) -> Runner
}

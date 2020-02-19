import BuildArtifacts
import Foundation
import Models
import PluginSupport
import QueueModels
import RunnerModels
import SimulatorPoolModels

final class GroupedTestEntryConfigurations {
    private let testEntryConfigurations: [TestEntryConfiguration]
    
    public init(testEntryConfigurations: [TestEntryConfiguration]) {
        self.testEntryConfigurations = testEntryConfigurations
    }
    
    public func grouped() -> [[TestEntryConfiguration]] {
        struct Key: Hashable {
            let buildArtifacts: BuildArtifacts
            let developerDir: DeveloperDir
            let pluginLocations: Set<PluginLocation>
            let simulatorControlTool: SimulatorControlTool
            let simulatorOperationTimeouts: SimulatorOperationTimeouts
            let simulatorSettings: SimulatorSettings
            let testDestination: TestDestination
            let testExecutionBehavior: TestExecutionBehavior
            let testRunnerTool: TestRunnerTool
            let testTimeoutConfiguration: TestTimeoutConfiguration
            let testType: TestType
        }
        
        var groups = MapWithCollection<Key, TestEntryConfiguration>()
        
        for testEntryConfiguration in testEntryConfigurations {
            let key = Key(
                buildArtifacts: testEntryConfiguration.buildArtifacts,
                developerDir: testEntryConfiguration.developerDir,
                pluginLocations: testEntryConfiguration.pluginLocations,
                simulatorControlTool: testEntryConfiguration.simulatorControlTool,
                simulatorOperationTimeouts: testEntryConfiguration.simulatorOperationTimeouts,
                simulatorSettings: testEntryConfiguration.simulatorSettings,
                testDestination: testEntryConfiguration.testDestination,
                testExecutionBehavior: testEntryConfiguration.testExecutionBehavior,
                testRunnerTool: testEntryConfiguration.testRunnerTool,
                testTimeoutConfiguration: testEntryConfiguration.testTimeoutConfiguration,
                testType: testEntryConfiguration.testType
            )
            
            groups.append(key: key, element: testEntryConfiguration)
        }

        let groupedConfigurations = groups.values
        let groupedConfigurationsWithUniqueTestEntries = splitGroupsToContainUniqueTestEntries(
            groupedConfigurations: groupedConfigurations
        )
        
        return groupedConfigurationsWithUniqueTestEntries.sorted { $0.count > $1.count }
    }

    private func splitGroupsToContainUniqueTestEntries(
        groupedConfigurations: [[TestEntryConfiguration]]
    ) -> [[TestEntryConfiguration]] {
        return groupedConfigurations.map { splitConfigurations($0) }.flatMap { $0 }
    }

    private func splitConfigurations(_ configurations: [TestEntryConfiguration]) -> [[TestEntryConfiguration]] {
        var splitedConfigurations = [[TestEntryConfiguration]()]
        for configuration in configurations {
            var splitCount = 0
            while true {
                if splitCount == splitedConfigurations.count {
                    splitedConfigurations.append([configuration])
                    break
                }

                let containsConfiguration = splitedConfigurations[splitCount].contains {
                    $0.testEntry == configuration.testEntry
                }
                if containsConfiguration == false {
                    splitedConfigurations[splitCount].append(configuration)
                    break
                }

                splitCount += 1
            }

        }

        return splitedConfigurations
    }
}

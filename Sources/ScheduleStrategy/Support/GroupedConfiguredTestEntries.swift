import BuildArtifacts
import DeveloperDirModels
import Foundation
import PluginSupport
import QueueModels
import SimulatorPoolModels
import Types
import WorkerCapabilitiesModels

final class GroupedConfiguredTestEntry {
    private let configuredTestEntries: [ConfiguredTestEntry]
    
    public init(configuredTestEntries: [ConfiguredTestEntry]) {
        self.configuredTestEntries = configuredTestEntries
    }
    
    public func grouped() -> [[ConfiguredTestEntry]] {
        var groups = MapWithCollection<TestEntryConfiguration, ConfiguredTestEntry>()
        
        for configuredTestEntry in configuredTestEntries {
            groups.append(key: configuredTestEntry.testEntryConfiguration, element: configuredTestEntry)
        }

        let groupedConfigurationsWithUniqueTestEntries = splitGroupsToContainUniqueTestEntries(
            groupedConfiguredTestEntry: groups.values
        )
        
        return groupedConfigurationsWithUniqueTestEntries.sorted { $0.count > $1.count }
    }

    private func splitGroupsToContainUniqueTestEntries(
        groupedConfiguredTestEntry: [[ConfiguredTestEntry]]
    ) -> [[ConfiguredTestEntry]] {
        return groupedConfiguredTestEntry.map { splitConfiguredTestEntry($0) }.flatMap { $0 }
    }

    private func splitConfiguredTestEntry(
        _ configuredTestEntries: [ConfiguredTestEntry]
    ) -> [[ConfiguredTestEntry]] {
        var result = [[ConfiguredTestEntry]()]
        
        for configuredTestEntry in configuredTestEntries {
            var splitCount = 0
            while true {
                if splitCount == result.count {
                    result.append([configuredTestEntry])
                    break
                }

                let containsConfiguration = result[splitCount].contains {
                    $0.testEntry == configuredTestEntry.testEntry
                }
                if containsConfiguration == false {
                    result[splitCount].append(configuredTestEntry)
                    break
                }

                splitCount += 1
            }

        }

        return result
    }
}

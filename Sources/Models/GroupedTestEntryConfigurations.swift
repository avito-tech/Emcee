import Foundation

public final class GroupedTestEntryConfigurations {
    private let testEntryConfigurations: [TestEntryConfiguration]
    
    public init(testEntryConfigurations: [TestEntryConfiguration]) {
        self.testEntryConfigurations = testEntryConfigurations
    }
    
    public func grouped() -> [[TestEntryConfiguration]] {
        struct Key: Hashable {
            let buildArtifacts: BuildArtifacts
            let testDestination: TestDestination
            let testExecutionBehavior: TestExecutionBehavior
            let testType: TestType
        }
        
        var groups = MapWithCollection<Key, TestEntryConfiguration>()
        
        for testEntryConfiguration in testEntryConfigurations {
            let key = Key(
                buildArtifacts: testEntryConfiguration.buildArtifacts,
                testDestination: testEntryConfiguration.testDestination,
                testExecutionBehavior: testEntryConfiguration.testExecutionBehavior,
                testType: testEntryConfiguration.testType
            )
            
            groups.append(key: key, element: testEntryConfiguration)
        }
        
        return groups.values.sorted { $0.count > $1.count }
    }
}

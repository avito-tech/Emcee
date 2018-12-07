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
        }
        
        var groups = [Key: [TestEntryConfiguration]]()
        
        for testEntryConfiguration in testEntryConfigurations {
            let key = Key(
                buildArtifacts: testEntryConfiguration.buildArtifacts,
                testDestination: testEntryConfiguration.testDestination,
                testExecutionBehavior: testEntryConfiguration.testExecutionBehavior
            )
            
            if let group = groups[key] {
                groups[key] = group + [testEntryConfiguration]
            } else {
                groups[key] = [testEntryConfiguration]
            }
        }
        
        return groups.values.sorted { $0.count > $1.count }
    }
}

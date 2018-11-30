import Foundation

public final class GroupedTestEntryConfigurations {
    private let testEntryConfigurations: [TestEntryConfiguration]
    
    public init(testEntryConfigurations: [TestEntryConfiguration]) {
        self.testEntryConfigurations = testEntryConfigurations
    }
    
    public func grouped() -> [[TestEntryConfiguration]] {
        struct Key: Hashable {
            let testDestination: TestDestination
            let testExecutionBehavior: TestExecutionBehavior
            let buildArtifacts: BuildArtifacts
        }
        
        var groups = [Key: [TestEntryConfiguration]]()
        
        for testEntryConfiguration in testEntryConfigurations {
            let key = Key(
                testDestination: testEntryConfiguration.testDestination,
                testExecutionBehavior: testEntryConfiguration.testExecutionBehavior,
                buildArtifacts: testEntryConfiguration.buildArtifacts
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

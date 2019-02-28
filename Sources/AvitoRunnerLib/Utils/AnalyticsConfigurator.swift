import Foundation
import LoggingSetup
import Models
import ResourceLocationResolver

public final class AnalyticsConfigurator {
    private let resourceLocationResolver: ResourceLocationResolver
    private let decoder = JSONDecoder()
    
    public init(resourceLocationResolver: ResourceLocationResolver) {
        self.resourceLocationResolver = resourceLocationResolver
    }
    
    public func setup(analyticsConfigurationLocation: AnalyticsConfigurationLocation) throws {
        let resolvingResult = try resourceLocationResolver.resolvePath(
            resourceLocation: analyticsConfigurationLocation.resourceLocation
        )
        let data = try Data(contentsOf: URL(fileURLWithPath: try resolvingResult.directlyAccessibleResourcePath()))
        let analyticsConfiguration = try decoder.decode(AnalyticsConfiguration.self, from: data)
        try LoggingSetup.setupAnalytics(analyticsConfiguration: analyticsConfiguration)
    }
}

import Foundation

/// Represents locatios of the tools that are used by the runner.
public struct AuxiliaryResources {
    public let toolResources: ToolResources
    
    /// Locations of .emceeplugin bundles.
    public let plugins: [PluginLocation]
    
    public init(
        toolResources: ToolResources,
        plugins: [PluginLocation])
    {
        self.toolResources = toolResources
        self.plugins = plugins
    }
}

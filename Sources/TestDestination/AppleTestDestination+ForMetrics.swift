
extension AppleTestDestination {
    public var deviceTypeForMetrics: String {
        guard let value = simDeviceType.split(separator: ".").last else {
            return "unknown_device_type"
        }
        return value.replacingOccurrences(of: "-", with: "_")
    }
    
    public var runtimeForMetrics: String {
        guard let value = simRuntime.split(separator: ".").last else {
            return "unknown_runtime"
        }
        return value.replacingOccurrences(of: "-", with: "_")
    }
}

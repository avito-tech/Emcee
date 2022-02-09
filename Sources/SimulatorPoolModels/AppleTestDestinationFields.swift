import Foundation

public enum AppleTestDestinationFields {
    /// Device type. Examples:
    /// - `com.apple.CoreSimulator.SimDeviceType.iPhone-X`
    /// - `com.apple.CoreSimulator.SimDeviceType.iPad-mini-6th-generation`
    /// - `com.apple.CoreSimulator.SimDeviceType.Apple-TV-4K-4K`
    public static let simDeviceType: String = "simDeviceType"
    
    /// Platform-specific runtime. Examples:
    /// - `com.apple.CoreSimulator.SimRuntime.iOS-15-1`
    /// - `com.apple.CoreSimulator.SimRuntime.tvOS-15-0`
    public static let simRuntime: String = "simRuntime"
    
    /// Old-style, e.g. `iPhone SE`
    public static let deviceType: String = "deviceType"
    
    /// Old-style, e.g. `15.0`. `iOS` implied.
    public static let runtime: String = "runtime"
}

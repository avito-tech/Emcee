import TestDestination

extension TestDestination {
    /// - Parameters:
    ///   - deviceType: Human-readable device name, e.g. `iPhone X`. All `.,()` symbols will be replaced with `-` in attempt to match `SimDeviceType` name.
    ///   - version: Human-readable OS version, e.g. `15.0`. All `.` symbols will be replaced with `-` in attempt to match `SimRuntime` name.
    public static func iOSSimulator(
        deviceType: String,
        version: String
    ) -> Self {
        appleSimulator(deviceType: deviceType, kind: .iOS, version: version)
    }
    
    /// - Parameters:
    ///   - deviceType: Human-readable device name, e.g. `Apple TV 4K 4K`. All `.,()` symbols will be replaced with `-` in attempt to match `SimDeviceType` name.
    ///   - version: Human-readable OS version, e.g. `15.0`. All `.` symbols will be replaced with `-` in attempt to match `SimRuntime` name.
    public static func tvOSSimulator(
        deviceType: String,
        version: String
    ) -> Self {
        appleSimulator(deviceType: deviceType, kind: .tvOS, version: version)
    }
    
    /// - Parameters:
    ///   - deviceType: Human-readable device name, e.g. `iPhone X`. All `.,()` symbols will be replaced with `-` in attempt to match `SimDeviceType` name.
    ///   - kind: Runtime kind, e.g. tvOS or iOS
    ///   - version: Human-readable OS version, e.g. `15.0`. All `.` symbols will be replaced with `-` in attempt to match `SimRuntime` name.
    public static func appleSimulator(
        deviceType: String,
        kind: AppleRuntimeKind,
        version: String
    ) -> Self {
        Self.appleSimulator(
            simDeviceType: SimDeviceType(
                fullyQualifiedId: "com.apple.CoreSimulator.SimDeviceType." + deviceType
                    .replacingOccurrences(of: " ", with: "-")
                    .replacingOccurrences(of: ".", with: "-")
                    .replacingOccurrences(of: "(", with: "-")
                    .replacingOccurrences(of: ")", with: "-")
            ),
            simRuntime: SimRuntime(
                fullyQualifiedId: "com.apple.CoreSimulator.SimRuntime.\(kind.rawValue)-" + version
                    .replacingOccurrences(of: ".", with: "-")
            )
        )
    }
    
    /// - Parameters:
    ///   - simDeviceType: Fully qualified simDeviceType, e.g. `com.apple.CoreSimulator.SimDeviceType.iPad-Pro--12-9-inch---4th-generation-`
    ///   - simRuntime: Fully qualified simruntime id, e.g. `com.apple.CoreSimulator.SimRuntime.tvOS-15-0`
    public static func appleSimulator(
        simDeviceType: SimDeviceType,
        simRuntime: SimRuntime
    ) -> Self {
        Self()
            .add(
                key: AppleTestDestinationFields.simDeviceType,
                value: simDeviceType.fullyQualifiedId
            )
            .add(
                key: AppleTestDestinationFields.simRuntime,
                value: simRuntime.fullyQualifiedId
            )
    }
}

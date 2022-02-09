import TestDestination

extension TestDestination {
    /// - Parameters:
    ///   - deviceType: Emulated device, e.g. `Nexus`
    ///   - sdkVersion: Emulator SDK version, e.g. `23`
    public static func androidEmulator(
        deviceType: String,
        sdkVersion: Int
    ) -> Self {
        Self()
            .add(
                key: AndroidTestDestinationFields.deviceType,
                value: deviceType
            )
            .add(
                key: AndroidTestDestinationFields.sdkVersion,
                value: sdkVersion
            )
    }
}

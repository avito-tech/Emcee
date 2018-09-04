import Foundation

public struct TestTimeoutConfiguration: Codable {
    /** A maximum duration for a single test. */
    public let singleTestMaximumDuration: TimeInterval
    
    /** A maximum allowed duration for a fbxctest stdout/stderr to be silent. */
    public let fbxctestSilenceMaximumDuration: TimeInterval?
    
    /** Fbxctest internal timeout */
    public let fbxtestFastTimeout: TimeInterval?
    
    /** Fbxctest internal timeout */
    public let fbxtestRegularTimeout: TimeInterval?
    
    /** Fbxctest internal timeout */
    public let fbxtestSlowTimeout: TimeInterval?
    
    /** Time for `_XCT_testBundleReadyWithProtocolVersion` to be called after the 'connect'. */
    public let fbxtestBundleReadyTimeout: TimeInterval?
    
    /** Time to wait for crash report to be generated. */
    public let fbxtestCrashCheckTimeout: TimeInterval?

    public init(
        singleTestMaximumDuration: TimeInterval,
        fbxctestSilenceMaximumDuration: TimeInterval? = nil,
        fbxtestFastTimeout: TimeInterval? = nil,
        fbxtestRegularTimeout: TimeInterval? = nil,
        fbxtestSlowTimeout: TimeInterval? = nil,
        fbxtestBundleReadyTimeout: TimeInterval? = nil,
        fbxtestCrashCheckTimeout: TimeInterval? = nil)
    {
        self.singleTestMaximumDuration = singleTestMaximumDuration
        self.fbxctestSilenceMaximumDuration = fbxctestSilenceMaximumDuration
        self.fbxtestFastTimeout = fbxtestFastTimeout
        self.fbxtestRegularTimeout = fbxtestRegularTimeout
        self.fbxtestSlowTimeout = fbxtestSlowTimeout
        self.fbxtestBundleReadyTimeout = fbxtestBundleReadyTimeout
        self.fbxtestCrashCheckTimeout = fbxtestCrashCheckTimeout
    }
}

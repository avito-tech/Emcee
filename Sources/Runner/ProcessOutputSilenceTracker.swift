import DateProvider
import FileSystem
import Foundation
import Logging
import ProcessController
import Timer

public final class ProcessOutputSilenceTracker {
    private let dateProvider: DateProvider
    private let fileSystem: FileSystem
    private let onSilence: () -> ()
    private let silenceDuration: TimeInterval
    private let standardStreamsCaptureConfig: StandardStreamsCaptureConfig
    private let subprocessInfo: SubprocessInfo
    private var timer: DispatchBasedTimer?
    
    public init(
        dateProvider: DateProvider,
        fileSystem: FileSystem,
        onSilence: @escaping () -> (),
        silenceDuration: TimeInterval,
        standardStreamsCaptureConfig: StandardStreamsCaptureConfig,
        subprocessInfo: SubprocessInfo
    ) {
        self.dateProvider = dateProvider
        self.fileSystem = fileSystem
        self.onSilence = onSilence
        self.silenceDuration = silenceDuration
        self.standardStreamsCaptureConfig = standardStreamsCaptureConfig
        self.subprocessInfo = subprocessInfo
    }
    
    deinit {
        timer?.stop()
    }
    
    public func startTracking() {
        timer = DispatchBasedTimer.startedTimer(
            repeating: .seconds(1),
            leeway: .seconds(1)
        ) { [weak self] sender in
            guard let strongSelf = self else { return sender.stop() }
            strongSelf.verifyProcessOutputsAnyData()
        }
    }
    
    public func stopTracking() {
        timer?.stop()
    }
    
    private func verifyProcessOutputsAnyData() {
        do {
            let currentDate = dateProvider.currentDate()
            let stdoutMtime = try fileSystem.properties(forFileAtPath: standardStreamsCaptureConfig.stdoutContentsFile).modificationDate()
            let stderrMtime = try fileSystem.properties(forFileAtPath: standardStreamsCaptureConfig.stderrContentsFile).modificationDate()
            
            if currentDate.timeIntervalSince(stdoutMtime) > silenceDuration,
                currentDate.timeIntervalSince(stderrMtime) > silenceDuration {
                timer?.stop()
                Logger.debug("Process has been silent for more than \(LoggableDuration(silenceDuration))", subprocessInfo)
                onSilence()
            }
        } catch {
            timer?.stop()
            Logger.warning("Failed to check for process output mtime: \(error). Will stop tracking for process aliveness.", subprocessInfo)
        }
    }
}

public extension ProcessOutputSilenceTracker {
    func whileTracking<T>(work: () throws -> T) rethrows -> T {
        startTracking()
        defer {
            stopTracking()
        }
        return try work()
    }
}

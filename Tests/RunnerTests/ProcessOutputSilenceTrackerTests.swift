import DateProviderTestHelpers
import FileSystemTestHelpers
import Foundation
import Logging
import PathLib
import ProcessController
import Runner
import TemporaryStuff
import TestHelpers
import XCTest

final class ProcessOutputSilenceTrackerTests: XCTestCase {
    lazy var dateProvider = DateProviderFixture()
    lazy var expectation = XCTestExpectation()
    lazy var fileSystem = FakeFileSystem(rootPath: AbsolutePath(#file))
    lazy var standardStreamsCaptureConfig = StandardStreamsCaptureConfig(
        stdoutPath: tempFolder.absolutePath.appending(component: "stdout.txt"),
        stderrPath: tempFolder.absolutePath.appending(component: "stderr.txt")
    )
    lazy var subprocessInfo = SubprocessInfo(subprocessId: 1234, subprocessName: "process_name")
    lazy var tempFolder = assertDoesNotThrow { try TemporaryFolder() }
    lazy var tracker = ProcessOutputSilenceTracker(
        dateProvider: dateProvider,
        fileSystem: fileSystem,
        onSilence: expectation.fulfill,
        silenceDuration: 5.0,
        standardStreamsCaptureConfig: standardStreamsCaptureConfig,
        subprocessInfo: subprocessInfo
    )
    lazy var pathMtimes = [AbsolutePath: Date]()
    
    override func setUp() {
        fileSystem.propertiesProvider = { [weak self] askedPath in
            let container = FakeFilePropertiesContainer(path: askedPath)
            
            if let mtime = self?.pathMtimes[askedPath] {
                container.mdate = mtime
            } else {
                container.mdate = Date(timeIntervalSince1970: 500)
            }

            return container
        }
    }
    
    func test___when_process_outputs_to_stdout___silence_not_triggered() throws {
        pathMtimes[try standardStreamsCaptureConfig.stdoutOutputPath()] = dateProvider.currentDate()
        expectation.isInverted = true
        
        tracker.startTracking()
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func test___when_process_outputs_to_stderr___silence_not_triggered() throws {
        pathMtimes[try standardStreamsCaptureConfig.stderrOutputPath()] = dateProvider.currentDate()
        expectation.isInverted = true

        tracker.startTracking()
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func test___when_process_does_not_output_anything___silence_is_triggered() {
        tracker.startTracking()
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func test___when_process_becomes_silent___it_reports_silence() throws {
        pathMtimes[try standardStreamsCaptureConfig.stdoutOutputPath()] = dateProvider.currentDate()
        pathMtimes[try standardStreamsCaptureConfig.stderrOutputPath()] = dateProvider.currentDate()
        
        tracker.startTracking()
        
        DispatchQueue.main.async {
            self.dateProvider.result += 6.0
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func test___when_stop_is_called___it_does_not_report_silence() throws {
        expectation.isInverted = true
        
        pathMtimes[try standardStreamsCaptureConfig.stdoutOutputPath()] = dateProvider.currentDate()
        pathMtimes[try standardStreamsCaptureConfig.stderrOutputPath()] = dateProvider.currentDate()
        
        tracker.startTracking()
        tracker.stopTracking()
        
        DispatchQueue.main.async {
            self.dateProvider.result += 6.0
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
}

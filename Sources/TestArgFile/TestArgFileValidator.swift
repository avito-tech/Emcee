import BuildArtifacts
import Foundation
import RunnerModels
import SimulatorPoolModels

public final class TestArgFileValidator {
    public init() {}
    
    public struct TestArgFileValidationError: Error, CustomStringConvertible {
        public let errors: [Error]
        
        public var description: String {
            "Test arg file has the following errors:\n" + errors.map { "\($0)" }.joined(separator: "\n")
        }
    }
    
    private struct EntryValidationError: Error, CustomStringConvertible {
        let entryIndex: Int
        let error: Error
        
        var description: String {
            "Test arg file entry at index \(entryIndex) has configuration error: \(error)"
        }
    }
    
    public func validate(testArgFile: TestArgFile) throws {
        var errors = [EntryValidationError]()
        
        for (index, entry) in testArgFile.entries.enumerated() {
            do {
                try validate(entry: entry)
            } catch {
                errors.append(EntryValidationError(entryIndex: index, error: error))
            }
        }
        
        if !errors.isEmpty {
            throw TestArgFileValidationError(errors: errors)
        }
    }
    
    private func validate(entry: TestArgFileEntry) throws {
        try validate(simulatorControlTool: entry.simulatorControlTool, testRunnerTool: entry.testRunnerTool)
    }
    
    private func validate(simulatorControlTool: SimulatorControlTool, testRunnerTool: TestRunnerTool) throws {
        enum SimulatorToolAndTestRunnerToolMisconfiguration: Error, CustomStringConvertible {
            case xcodebuildAndSimulatorLocationIncompatibility(simulatorLocation: SimulatorLocation)
            
            var description: String {
                switch self {
                case .xcodebuildAndSimulatorLocationIncompatibility(let simulatorLocation):
                    return "xcodebuild is not compatible with provided simulator location (\(simulatorLocation.rawValue)). Use \(SimulatorLocation.insideUserLibrary.rawValue) instead."
                }
            }
        }
        
        switch (simulatorControlTool.location, testRunnerTool) {
        case (.insideEmceeTempFolder, .xcodebuild):
            throw SimulatorToolAndTestRunnerToolMisconfiguration.xcodebuildAndSimulatorLocationIncompatibility(simulatorLocation: simulatorControlTool.location)
        default:
            return
        }
    }
}

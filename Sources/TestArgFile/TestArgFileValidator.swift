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
                try validate(entry: entry, index: index)
            } catch {
                errors.append(EntryValidationError(entryIndex: index, error: error))
            }
        }
        
        if !errors.isEmpty {
            throw TestArgFileValidationError(errors: errors)
        }
    }
    
    private func validate(entry: TestArgFileEntry, index: Int) throws {
        try validate(buildArtifacts: entry.buildArtifacts, testType: entry.testType)
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
    
    private func validate(buildArtifacts: BuildArtifacts, testType: TestType) throws {
        enum BuildArtifactsValidationError: Error, CustomStringConvertible {
            case missingBuildArtifact(TestType, kind: String)
            var description: String {
                switch self {
                case .missingBuildArtifact(let testType, let kind):
                    return "Test type \(testType.rawValue) requires \(kind) to be provided"
                }
            }
        }
        
        switch testType {
        case .logicTest:
            break
        case .appTest:
            if buildArtifacts.appBundle == nil {
                throw BuildArtifactsValidationError.missingBuildArtifact(testType, kind: "appBundle")
            }
        case .uiTest:
            if buildArtifacts.appBundle == nil {
                throw BuildArtifactsValidationError.missingBuildArtifact(testType, kind: "appBundle")
            }
            if buildArtifacts.runner == nil {
                throw BuildArtifactsValidationError.missingBuildArtifact(testType, kind: "runner (XCTRunner.app)")
            }
        }
    }
}

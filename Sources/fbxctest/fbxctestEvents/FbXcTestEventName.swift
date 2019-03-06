import Foundation

public enum FbXcTestEventName: String, Codable {
    case didCopyTestArtifact = "copy-test-artifact"
    case osLogSaved = "os-log-saved"
    case runnerAppLogSaved = "runner-app-log-saved"
    case testDetectedDebugger = "end-status"
    case testFinished = "end-test"
    case testIsWaitingForDebugger = "begin-status"
    case testOutput = "test-output"
    case testPlanError = "test-plan-error"
    case testPlanFinished = "end-ocunit"
    case testPlanStarted = "begin-ocunit"
    case testStarted = "begin-test"
    case testSuiteFinished = "end-test-suite"
    case testSuiteStarted = "begin-test-suite"
    case videoRecordingFinished = "video-recording-finished"
}

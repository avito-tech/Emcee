import Extensions
import Foundation
import Logging
import TestingFakeFbxctest

func fakeFbxctestMain() -> Int32 {
    guard let runId = ProcessInfo.processInfo.environment["EMCEE_TESTS_RUN_ID"] else { return 5 }
    let binaryContainerPath = ProcessInfo.processInfo.executablePath.deletingLastPathComponent
    let filePrefix = "\(runId)_\(FakeFbxctestExecutableProducer.fakeOutputJsonFilename.deletingPathExtension)"
    let jsonOutputFiles = try? FileManager.default.findFiles(
        path: binaryContainerPath,
        prefix: filePrefix,
        pathExtension: FakeFbxctestExecutableProducer.fakeOutputJsonFilename.pathExtension).sorted()
    guard let jsonFile = jsonOutputFiles?.first else {
        return 0
    }
    log("Using json: \(jsonFile)")
    if let contents = try? String(contentsOf: URL(fileURLWithPath: jsonFile)) {
        formatlessStdout(contents)
    }
    try? FileManager.default.removeItem(atPath: jsonFile)
    return 0
}

exit(fakeFbxctestMain())

import Extensions
import Foundation
import TestingFakeFbxctest

func fakeFbxctestMain() -> Int32 {
    guard ProcessInfo.processInfo.environment["DEVELOPER_DIR"] != nil else { return 5 }
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
    var stdout = FileHandle.standardOutput
    if let contents = try? String(contentsOf: URL(fileURLWithPath: jsonFile)) {
        // swiftlint:disable:next print
        print(contents, to: &stdout)
    }
    try? FileManager.default.removeItem(atPath: jsonFile)
    return 0
}

exit(fakeFbxctestMain())

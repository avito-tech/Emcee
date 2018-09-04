import Extensions
import Foundation
import Logging
import TestingFakeFbxctest

func fakeFbxctestMain() -> Int32 {
    let binaryContainerPath = ProcessInfo.processInfo.arguments[0].deletingLastPathComponent
    let jsonOutputFiles = try? FileManager.default.findFiles(
        path: binaryContainerPath,
        prefix: FakeFbxctestExecutableProducer.fakeOutputJsonFilename.deletingPathExtension,
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

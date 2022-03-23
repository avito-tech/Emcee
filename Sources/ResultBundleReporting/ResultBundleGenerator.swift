import Foundation
import PathLib
import ProcessController
import Tmp
import EmceeLogging

public final class ResultBundleGenerator {
    private enum ResultBundleGeneratorError: Error, CustomStringConvertible {
        case missingResultBundle(path: AbsolutePath)
        
        var description: String {
            switch self {
            case .missingResultBundle(let path):
                return "Missing result bundle at path \(path)"
            }
        }
    }
    
    private let processControllerProvider: ProcessControllerProvider
    private let tempFolder: TemporaryFolder
    private let logger: ContextualLogger
    
    public init(
        processControllerProvider: ProcessControllerProvider,
        tempFolder: TemporaryFolder,
        logger: ContextualLogger
    ) {
        self.processControllerProvider = processControllerProvider
        self.tempFolder = tempFolder
        self.logger = logger
    }
    
    public func writeReport(
        xcresultData: [Data],
        path: String
    ) throws {
        let temporaryDirectory = try tempFolder.createDirectory(components: [])
        
        var resultBundlePaths: [AbsolutePath] = []
        try xcresultData.forEach { zippedData in
            let archiveId = UUID().uuidString
            let xcresultArchivePath = temporaryDirectory.appending(
                "ziped_xcresult_\(archiveId).zip"
            )
            
            try zippedData.write(
                to: xcresultArchivePath.fileUrl
            )
            
            let xcresultContentsPath = temporaryDirectory.appending(
                "ziped_xcresult_\(archiveId)"
            )
            try processControllerProvider.createProcessController(
                subprocess: Subprocess(
                    arguments: ["/usr/bin/unzip", xcresultArchivePath, "-d", xcresultContentsPath]
                )
            ).startAndWaitForSuccessfulTermination()
            
            let resultBundlePath = xcresultContentsPath.appending("resultBundle.xcresult")
            guard FileManager().fileExists(atPath: resultBundlePath.pathString) else {
                throw ResultBundleGeneratorError.missingResultBundle(path: resultBundlePath)
            }
            
            resultBundlePaths.append(resultBundlePath)
        }
        
        switch resultBundlePaths.count {
        case 0:
            logger.error("No result bundles to write out")
        case 1:
            try FileManager().copyItem(
                atPath: resultBundlePaths[0].pathString,
                toPath: path
            )
        default:
            let resultBundleProcessController = try processControllerProvider.createProcessController(
                subprocess: Subprocess(
                    arguments: ["/usr/bin/xcrun", "xcresulttool", "merge"]
                    + resultBundlePaths.map(\.pathString)
                    + ["--output-path", path]
                )
            )
            resultBundleProcessController.restreamOutput()
            try resultBundleProcessController.startAndWaitForSuccessfulTermination()
        }
    }
    
}

import EmceeLogging
import FileSystem
import Foundation
import PathLib

public protocol ResultBundleUploader {
    func uploadResultBundle(
        zippedResultBundleOutputPath: AbsolutePath,
        resultBundlesUploadUrl: URL
    )
}

public final class ResultBundlerUploaderImpl: ResultBundleUploader {
    
    private let fileSystem: FileSystem
    private let logger: ContextualLogger
    
    public init(
        fileSystem: FileSystem,
        logger: ContextualLogger
    ) {
        self.fileSystem = fileSystem
        self.logger = logger
    }
    
    public func uploadResultBundle(
        zippedResultBundleOutputPath: AbsolutePath,
        resultBundlesUploadUrl: URL
    ) {
        guard fileSystem.exists(path: zippedResultBundleOutputPath) else {
            logger.error("Missing expected zipped result bundle at \(zippedResultBundleOutputPath)")
            return
        }
        
        guard let zippedResultBundleContents = FileManager().contents(
            atPath: zippedResultBundleOutputPath.pathString
        ) else {
            logger.error("Can't read result bundle at path \(zippedResultBundleOutputPath)")
            return
        }
        
        guard var components = URLComponents(
            url: resultBundlesUploadUrl,
            resolvingAgainstBaseURL: true
        ) else {
            logger.error("Couldn't create components from url \(resultBundlesUploadUrl)")
            return
        }
        components.queryItems = [
            URLQueryItem(
                name: "filename",
                value: "\(UUID().uuidString)"
            )
        ]
        
        guard let url = components.url else {
            logger.error("Couldn't create url from components \(components)")
            return
        }
        
        var urlRequest = URLRequest(
            url: url,
            timeoutInterval: 600
        )
        urlRequest.httpMethod = "POST"
        
        let timeout: TimeInterval = 600
        
        let semaphore = DispatchSemaphore(value: 0)
        let configuation = URLSessionConfiguration.default
        configuation.timeoutIntervalForRequest = timeout
        URLSession(configuration: configuation).uploadTask(
            with: urlRequest,
            from: zippedResultBundleContents,
            completionHandler: { [logger] data, response, error in
                logger.trace("Bundle upload \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                if let error = error {
                    logger.error("Bundle upload error: \(error)")
                }
                semaphore.signal()
            }
        ).resume()
        
        if semaphore.wait(timeout: .now() + timeout) == .timedOut {
            logger.error("Bundle upload timed out")
        }
    }
    
}

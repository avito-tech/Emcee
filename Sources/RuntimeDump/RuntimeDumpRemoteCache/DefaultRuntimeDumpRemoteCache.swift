import Foundation
import RequestSender
import Logging
import Models
import SynchronousWaiter
import PathLib

class DefaultRuntimeDumpRemoteCache: RuntimeDumpRemoteCache {
    private let sender: RequestSender
    private let config: RuntimeDumpRemoteCacheConfig
    private let waiter: Waiter
    private let callbackQueue = DispatchQueue(
        label: "RuntimeDumpRemoteCache.callbackQueue",
        qos: .default,
        attributes: .concurrent,
        autoreleaseFrequency: .inherit,
        target: nil
    )

    init(
        config: RuntimeDumpRemoteCacheConfig,
        sender: RequestSender,
        waiter: Waiter = SynchronousWaiter()
    ) {
        self.config = config
        self.sender = sender
        self.waiter = waiter
    }

    func results(xcTestBundleLocation: TestBundleLocation) throws -> TestsInRuntimeDump? {
        let request = RuntimeDumpRemoteCacheResultRequest(
            httpMethod: config.obtainHttpMethod,
            pathWithLeadingSlash: pathToRemoteFile(xcTestBundleLocation)
        )

        var queryResult: Either<TestsInRuntimeDump, RequestSenderError>?

        sender.sendRequestWithCallback(
            request: request,
            credentials: config.credentials,
            callbackQueue: callbackQueue
        ) { result in
            queryResult = result
        }

        return try waiter.waitForUnwrap(
            timeout: 10,
            valueProvider: { try queryResult?.dematerialize() },
            description: "Cached query result"
        )
    }

    func store(tests: TestsInRuntimeDump, xcTestBundleLocation: TestBundleLocation) {
        let request = RentimeDumpRemoteCacheStoreRequest(
            httpMethod: config.storeHttpMethod,
            pathWithLeadingSlash: pathToRemoteFile(xcTestBundleLocation),
            payload: tests
        )

        sender.sendRequestWithCallback(
            request: request,
            credentials: config.credentials,
            callbackQueue: callbackQueue
        ) { (result: Either<EmptyData, RequestSenderError>) in
            Logger.verboseDebug("Stored runtime query with result: \(result)")
        }
    }

    private func pathToRemoteFile(_ xcTestBundleLocation: TestBundleLocation) -> String {
        return addLeadingSlashIfNeeded(config.relativePathToRemoteStorage).appending(
            pathComponent: "\(xcTestBundleLocation.hashValue).json"
        )
    }

    func addLeadingSlashIfNeeded(_ path: RelativePath) -> String {
        guard path.pathString.first != "/" else {
            return path.pathString
        }

        return "/\(path.pathString)"
    }
}

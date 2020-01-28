import Foundation
import RequestSender
import Logging
import Models

public class RuntimeDumpRemoteCache {
    private let sender: RequestSender
    private let config: RuntimeDumpRemoteCacheConfig
    private let callbackQueue = DispatchQueue(
        label: "RuntimeDumpRemoteCache.callbackQueue",
        qos: .default,
        attributes: .concurrent,
        autoreleaseFrequency: .inherit,
        target: nil
    )

    public init(
        config: RuntimeDumpRemoteCacheConfig,
        sender: RequestSender
    ) {
        self.config = config
        self.sender = sender
    }

    public func results(xcTestBundleLocation: TestBundleLocation, callback: @escaping (RuntimeQueryResult?) -> ()) {
        let request = RuntimeDumpRemoteCacheResultRequest(
            httpMethod: config.obtainHttpMethod,
            pathWithLeadingSlash: pathToRemoteFile(xcTestBundleLocation)
        )

        sender.sendRequestWithCallback(
            request: request,
            credentials: config.credentials,
            callbackQueue: callbackQueue
        ) { (result: Either<RuntimeQueryResult, RequestSenderError>) in
            callback(try? result.dematerialize())
        }
    }

    public func store(result: RuntimeQueryResult, xcTestBundleLocation: TestBundleLocation) {
        let request = RentimeDumpRemoteCacheStoreRequest(
            httpMethod: config.storeHttpMethod,
            pathWithLeadingSlash: pathToRemoteFile(xcTestBundleLocation),
            payload: result
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
        return addLeadingSlashIfNeeded(config.pathToRemoteStorage).appending(
            pathComponent: "\(xcTestBundleLocation.hashValue)"
        )
    }

    func addLeadingSlashIfNeeded(_ string: String) -> String {
        guard string.first != "/" else {
            return string
        }

        return "/\(string)"
    }
}

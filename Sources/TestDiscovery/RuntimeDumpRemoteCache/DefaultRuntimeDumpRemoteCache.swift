import AtomicModels
import BuildArtifacts
import Foundation
import EmceeLogging
import PathLib
import RequestSender
import SynchronousWaiter
import Types

class DefaultRuntimeDumpRemoteCache: RuntimeDumpRemoteCache {
    private let sender: RequestSender
    private let config: RuntimeDumpRemoteCacheConfig
    private let waiter: Waiter = SynchronousWaiter()
    private let callbackQueue = DispatchQueue(
        label: "RuntimeDumpRemoteCache.callbackQueue",
        qos: .default,
        attributes: .concurrent,
        autoreleaseFrequency: .inherit,
        target: .global(qos: .userInitiated)
    )

    init(
        config: RuntimeDumpRemoteCacheConfig,
        sender: RequestSender
    ) {
        self.config = config
        self.sender = sender
    }

    func results(xcTestBundleLocation: TestBundleLocation) throws -> DiscoveredTests? {
        let request = RuntimeDumpRemoteCacheResultRequest(
            httpMethod: config.obtainHttpMethod,
            pathWithLeadingSlash: try pathToRemoteFile(xcTestBundleLocation)
        )
        
        let callbackWaiter: CallbackWaiter<Either<DiscoveredTests, RequestSenderError>> = waiter.createCallbackWaiter()

        sender.sendRequestWithCallback(
            request: request,
            credentials: config.credentials,
            callbackQueue: callbackQueue
        ) { result in
            callbackWaiter.set(result: result)
        }

        return try callbackWaiter.wait(timeout: 10, description: "Fetch cached test discovery result").dematerialize()
    }

    func store(tests: DiscoveredTests, xcTestBundleLocation: TestBundleLocation) throws {
        let request = RuntimeDumpRemoteCacheStoreRequest(
            httpMethod: config.storeHttpMethod,
            pathWithLeadingSlash: try pathToRemoteFile(xcTestBundleLocation),
            payload: tests
        )
        
        let callbackWaiter: CallbackWaiter<RequestSenderError?> = waiter.createCallbackWaiter()

        sender.sendRequestWithCallback(
            request: request,
            credentials: config.credentials,
            callbackQueue: callbackQueue
        ) { (result: Either<VoidPayload, RequestSenderError>) in
            callbackWaiter.set(result: result.right)
        }
        
        _ = try callbackWaiter.wait(timeout: 20, description: "Runtime Dump Remote Cache Store")
    }

    private func pathToRemoteFile(_ xcTestBundleLocation: TestBundleLocation) throws -> String {
        let remoteFileName = try xcTestBundleLocation.resourceLocation.stringValue().avito_sha256Hash()

        return addLeadingSlashIfNeeded(config.relativePathToRemoteStorage).appending(
            pathComponent: "\(remoteFileName).json"
        )
    }

    func addLeadingSlashIfNeeded(_ path: RelativePath) -> String {
        guard path.pathString.first != "/" else {
            return path.pathString
        }

        return "/\(path.pathString)"
    }
}

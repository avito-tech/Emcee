import Deployer
import Dispatch
import Foundation
import Logging
import Models
import RequestSender
import RESTMethods

public class DefaultQueueCommunicationService: QueueCommunicationService {    
    private let requestSenderProvider: RequestSenderProvider
    private let remoteQueueDetector: RemoteQueueDetector
    private let requestTimeout: TimeInterval
    private let socketHost: String
    private let callbackQueue = DispatchQueue(
        label: "RuntimeDumpRemoteCache.callbackQueue",
        qos: .default,
        target: .global(qos: .userInitiated)
    )
    
    public init(
        requestTimeout: TimeInterval,
        socketHost: String,
        requestSenderProvider: RequestSenderProvider,
        remoteQueueDetector: RemoteQueueDetector
    ) {
        self.requestTimeout = requestTimeout
        self.socketHost = socketHost
        self.requestSenderProvider = requestSenderProvider
        self.remoteQueueDetector = remoteQueueDetector
    }
    
    public func workersToUtilize(
        deployments: [DeploymentDestination],
        completion: @escaping (Either<Set<WorkerId>, Error>) -> ()
    ) {
        do {
            let masterPort = try remoteQueueDetector.findMasterQueuePort(timeout: requestTimeout)
            Logger.debug("Found master queue port: \(masterPort)")

            let requestSender = requestSenderProvider.requestSender(
                socketAddress: SocketAddress(host: socketHost, port: masterPort)
            )

            requestSender.sendRequestWithCallback(
                request: WorkersToUtilizeRequest(deployments: deployments),
                callbackQueue: callbackQueue,
                callback: { (result: Either<WorkersToUtilizeResponse, RequestSenderError>) in
                    do {
                        let response = try result.dematerialize()
                        switch response {
                        case .workersToUtilize(workerIds: let workerIds):
                            completion(.success(workerIds))
                        }
                    } catch {
                        completion(.error(error))
                    }
                }
            )
        } catch {
            Logger.error("Failed to find master queue port: \(error)")
            return completion(Either.error(error))
        }
    }
}

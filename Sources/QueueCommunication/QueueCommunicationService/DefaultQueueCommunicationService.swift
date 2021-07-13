import Deployer
import Dispatch
import Foundation
import EmceeLogging
import QueueModels
import RESTMethods
import RequestSender
import SocketModels
import Types

public class DefaultQueueCommunicationService: QueueCommunicationService {
    private let logger: ContextualLogger
    private let requestSenderProvider: RequestSenderProvider
    private let remoteQueueDetector: RemoteQueueDetector
    private let requestTimeout: TimeInterval
    private let version: Version
    private let callbackQueue = DispatchQueue(
        label: "RuntimeDumpRemoteCache.callbackQueue",
        qos: .default,
        target: .global(qos: .userInitiated)
    )
    
    public init(
        logger: ContextualLogger,
        remoteQueueDetector: RemoteQueueDetector,
        requestSenderProvider: RequestSenderProvider,
        requestTimeout: TimeInterval,
        version: Version
    ) {
        self.logger = logger
        self.remoteQueueDetector = remoteQueueDetector
        self.requestSenderProvider = requestSenderProvider
        self.requestTimeout = requestTimeout
        self.version = version
    }
    
    public func workersToUtilize(
        deployments: [DeploymentDestination],
        completion: @escaping (Either<Set<WorkerId>, Error>) -> ()
    ) {
        do {
            let masterQueueAddress = try remoteQueueDetector.findMasterQueueAddress(timeout: requestTimeout)

            let requestSender = requestSenderProvider.requestSender(
                socketAddress: masterQueueAddress
            )

            let payload = WorkersToUtilizePayload(deployments: deployments, version: version)
            requestSender.sendRequestWithCallback(
                request: WorkersToUtilizeRequest(payload: payload),
                callbackQueue: callbackQueue
            ) { (result: Either<WorkersToUtilizeResponse, RequestSenderError>) in
                completion(
                    result.mapResult { response -> Set<WorkerId> in
                        switch response {
                        case let .workersToUtilize(workerIds):
                            return workerIds
                        }
                    }
                )
            }
        } catch {
            logger.error("Failed to find master queue port: \(error)")
            return completion(Either.error(error))
        }
    }
    
    public func deploymentDestinations(
        socketAddress: SocketAddress,
        completion: @escaping (Either<[DeploymentDestination], Error>) -> ()
    ) {
        let requestSender = requestSenderProvider.requestSender(
            socketAddress: socketAddress
        )
        
        requestSender.sendRequestWithCallback(
            request: DeploymentDestinationsRequest(),
            callbackQueue: callbackQueue
        ) { (result: Either<DeploymentDestinationsResponse, RequestSenderError>) in
            completion(
                result.mapResult { response -> [DeploymentDestination] in
                    switch response {
                    case let .deploymentDestinations(destinations):
                        return destinations
                    }
                }
            )
        }
    }
}

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
    private let version: Version
    private let callbackQueue = DispatchQueue(
        label: "RuntimeDumpRemoteCache.callbackQueue",
        qos: .default,
        target: .global(qos: .userInitiated)
    )
    
    public init(
        remoteQueueDetector: RemoteQueueDetector,
        requestSenderProvider: RequestSenderProvider,
        requestTimeout: TimeInterval,
        socketHost: String,
        version: Version
    ) {
        self.remoteQueueDetector = remoteQueueDetector
        self.requestSenderProvider = requestSenderProvider
        self.requestTimeout = requestTimeout
        self.socketHost = socketHost
        self.version = version
    }
    
    public func workersToUtilize(
        deployments: [DeploymentDestination],
        completion: @escaping (Either<Set<WorkerId>, Error>) -> ()
    ) {
        Logger.debug("Making request for workers to utilize. Version: \(version), deployments: \(deployments) ")
        do {
            let masterPort = try remoteQueueDetector.findMasterQueuePort(timeout: requestTimeout)

            let requestSender = requestSenderProvider.requestSender(
                socketAddress: SocketAddress(host: socketHost, port: masterPort)
            )

            let payload = WorkersToUtilizePayload(deployments: deployments, version: version)
            requestSender.sendRequestWithCallback(
                request: WorkersToUtilizeRequest(payload: payload),
                callbackQueue: callbackQueue,
                callback: { (result: Either<WorkersToUtilizeResponse, RequestSenderError>) in
                    do {
                        let response = try result.dematerialize()
                        switch response {
                        case .workersToUtilize(let workerIds):
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
    
    public func deploymentDestinations(
        port: Models.Port,
        completion: @escaping (Either<[DeploymentDestination], Error>) -> ()
    ) {
        let requestSender = requestSenderProvider.requestSender(
            socketAddress: SocketAddress(host: socketHost, port: port)
        )
        
        requestSender.sendRequestWithCallback(
            request: DeploymentDestinationsRequest(),
            callbackQueue: callbackQueue) { (result: Either<DeploymentDestinationsResponse, RequestSenderError>) in
                do {
                    let response = try result.dematerialize()
                    switch response {
                    case .deploymentDestinations(let destinations):
                        completion(.success(destinations))
                    }
                } catch {
                    completion(.error(error))
                }
        }
    }
}

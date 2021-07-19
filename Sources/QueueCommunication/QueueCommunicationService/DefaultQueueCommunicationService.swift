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
    private let callbackQueue = DispatchQueue(
        label: "RuntimeDumpRemoteCache.callbackQueue",
        qos: .default,
        target: .global(qos: .userInitiated)
    )
    
    public init(
        logger: ContextualLogger,
        remoteQueueDetector: RemoteQueueDetector,
        requestSenderProvider: RequestSenderProvider,
        requestTimeout: TimeInterval
    ) {
        self.logger = logger
        self.remoteQueueDetector = remoteQueueDetector
        self.requestSenderProvider = requestSenderProvider
        self.requestTimeout = requestTimeout
    }
    
    public func workersToUtilize(
        version: Version,
        workerIds: Set<WorkerId>,
        completion: @escaping (Either<Set<WorkerId>, Error>) -> ()
    ) {
        do {
            let masterQueueAddress = try remoteQueueDetector.findMasterQueueAddress(timeout: requestTimeout)

            let requestSender = requestSenderProvider.requestSender(
                socketAddress: masterQueueAddress
            )

            let payload = WorkersToUtilizePayload(
                version: version,
                workerIds: workerIds
            )
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
    
    public func queryQueueForWorkerIds(
        queueAddress: SocketAddress,
        completion: @escaping (Either<Set<WorkerId>, Error>) -> ()
    ) {
        let requestSender = requestSenderProvider.requestSender(
            socketAddress: queueAddress
        )
        
        requestSender.sendRequestWithCallback(
            request: WorkerIdsRequest(),
            callbackQueue: callbackQueue
        ) { (result: Either<WorkerIdsResponse, RequestSenderError>) in
            completion(
                result.mapResult { response -> Set<WorkerId> in
                    response.workerIds
                }
            )
        }
    }
}

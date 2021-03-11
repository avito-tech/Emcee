import DistWorkerModels
import Foundation
import EmceeLogging
import RequestSender
import Timer
import Types
import WorkerAlivenessProvider

public final class WorkerAlivenessPoller {
    private let logger: ContextualLogger
    private let pollInterval: TimeInterval
    private let requestSenderProvider: RequestSenderProvider
    private let workerAlivenessProvider: WorkerAlivenessProvider
    private let workerDetailsHolder: WorkerDetailsHolder
    private var pollingTimer: DispatchBasedTimer?

    public init(
        logger: ContextualLogger,
        pollInterval: TimeInterval,
        requestSenderProvider: RequestSenderProvider,
        workerAlivenessProvider: WorkerAlivenessProvider,
        workerDetailsHolder: WorkerDetailsHolder
    ) {
        self.logger = logger.forType(Self.self)
        self.pollInterval = pollInterval
        self.requestSenderProvider = requestSenderProvider
        self.workerAlivenessProvider = workerAlivenessProvider
        self.workerDetailsHolder = workerDetailsHolder
    }

    public func startPolling() {
        pollingTimer = DispatchBasedTimer.startedTimer(
            repeating: DispatchTimeInterval.nanoseconds(Int(pollInterval * 1000 * 1000 * 1000)),
            leeway: .microseconds(100),
            handler: { [weak self] timer in
                guard let strongSelf = self else { return timer.stop() }
                strongSelf.performPoll()
            }
        )
    }
    
    public func stopPolling() {
        pollingTimer?.stop()
        pollingTimer = nil
    }
    
    private func performPoll() {
        let queue = DispatchQueue(label: "pollqueue")
        
        let group = DispatchGroup()
        
        for (workerId, socketAddress) in workerDetailsHolder.knownAddresses {
            group.enter()
            
            let sender = self.requestSenderProvider.requestSender(
                socketAddress: socketAddress
            )
            logger.debug("Polling \(workerId) for currently processing buckets")
            sender.sendRequestWithCallback(
                request: CurrentlyProcessingBucketsNetworkRequest(
                    timeout: pollInterval
                ),
                callbackQueue: queue,
                callback: { [weak self] (response: Either<CurrentlyProcessingBucketsResponse, RequestSenderError>) in
                    defer { group.leave() }
                    
                    guard let strongSelf = self else { return }
                    do {
                        let currentlyProcessingBucketsResponse = try response.dematerialize()
                        strongSelf.workerAlivenessProvider.set(
                            bucketIdsBeingProcessed: Set(currentlyProcessingBucketsResponse.bucketIds),
                            workerId: workerId
                        )
                    } catch {
                        strongSelf.logger.error("Failed to obtain currently processing buckets for \(workerId): \(error)")
                        strongSelf.workerAlivenessProvider.setWorkerIsSilent(
                            workerId: workerId
                        )
                    }
                }
            )
        }
        
        group.wait()
        logger.debug("Finished polling workers for currently processing buckets")
    }
}

import Dispatch
import EmceeLogging
import Foundation
import QueueModels
import SocketModels

public final class ClientSpecificLogStreamerProviderImpl: ClientSpecificLogStreamerProvider {
    private let clientDetailsHolder: ClientDetailsHolder
    private let logger: ContextualLogger
    
    private let logEntrySenderProvider: LogEntrySenderProvider
    private let queue: DispatchQueue
    private let willSendLogEntry: () -> ()
    private let didSendLogEntry: (Error?) -> ()
    
    public init(
        clientDetailsHolder: ClientDetailsHolder,
        logger: ContextualLogger,
        logEntrySenderProvider: LogEntrySenderProvider,
        queue: DispatchQueue,
        willSendLogEntry: @escaping () -> (),
        didSendLogEntry: @escaping (Error?) -> ()
    ) {
        self.clientDetailsHolder = clientDetailsHolder
        self.logger = logger
        self.logEntrySenderProvider = logEntrySenderProvider
        self.queue = queue
        self.willSendLogEntry = willSendLogEntry
        self.didSendLogEntry = didSendLogEntry
    }

    public func logStreamerForStreamingLogsIntoClientCreatedBucketId(
        bucketId: BucketId
    ) -> LogStreamer {
        guard let socketAddress = clientDetailsHolder.clientRestAddress(bucketId: bucketId) else {
            logger.skippingLoggingToQueue.warning("Can't get client for bucket \(bucketId)")
            return NoOpLogStreamer.instance
        }
        
        return ClientSpecificLogStreamer(
            clientRestSocketAddress: socketAddress,
            logEntrySenderProvider: logEntrySenderProvider,
            queue: queue,
            willSendLogEntry: willSendLogEntry,
            didSendLogEntry: didSendLogEntry
        )
    }
    
    
    public func logStreamerToAllClients() -> LogStreamer {
        CompoundLogStreamer(
            streamers: clientDetailsHolder.knownClientRestAddresses.map { socketAddress in
                ClientSpecificLogStreamer(
                    clientRestSocketAddress: socketAddress,
                    logEntrySenderProvider: logEntrySenderProvider,
                    queue: queue,
                    willSendLogEntry: willSendLogEntry,
                    didSendLogEntry: didSendLogEntry
                )
            }
        )
    }
}

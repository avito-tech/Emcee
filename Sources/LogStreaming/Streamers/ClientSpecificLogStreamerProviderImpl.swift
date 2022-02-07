import Dispatch
import EmceeLogging
import Foundation
import LogStreamingModels
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

    public func logStreamerToClientCreatedBucketId(
        bucketId: BucketId
    ) -> LogStreamer {
        guard let clientDetails = clientDetailsHolder.clientDetails(bucketId: bucketId) else {
            logger.skippingLoggingToQueue.warning("Can't get client for bucket \(bucketId)")
            return NoOpLogStreamer.instance
        }
        
        if clientDetails.clientLogStreamingMode.allowsJobSpecificLogStreaming {
            return ClientSpecificLogStreamer(
                clientRestSocketAddress: clientDetails.socketAddress,
                logEntrySenderProvider: logEntrySenderProvider,
                queue: queue,
                willSendLogEntry: willSendLogEntry,
                didSendLogEntry: didSendLogEntry
            )
        } else {
            return NoOpLogStreamer.instance
        }
    }
    
    public func logStreamerToAllClients() -> LogStreamer {
        CompoundLogStreamer(
            streamers: clientDetailsHolder.knownClientDetails.map { clientDetails in
                if clientDetails.clientLogStreamingMode.allowsGlobalLogStreaming {
                    return ClientSpecificLogStreamer(
                        clientRestSocketAddress: clientDetails.socketAddress,
                        logEntrySenderProvider: logEntrySenderProvider,
                        queue: queue,
                        willSendLogEntry: willSendLogEntry,
                        didSendLogEntry: didSendLogEntry
                    )
                } else {
                    return NoOpLogStreamer.instance
                }
            }
        )
    }
}

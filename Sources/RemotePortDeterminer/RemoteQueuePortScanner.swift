import AtomicModels
import Dispatch
import Foundation
import Logging
import Models
import QueueClient
import RequestSender
import Version

public final class RemoteQueuePortScanner: RemotePortDeterminer {
    private let host: String
    private let portRange: ClosedRange<Int>
    private let requestSenderProvider: RequestSenderProvider
    private let workQueue = DispatchQueue(label: "RemoteQueuePortScanner.workQueue")
    
    public init(
        host: String,
        portRange: ClosedRange<Int>,
        requestSenderProvider: RequestSenderProvider
    ) {
        self.host = host
        self.portRange = portRange
        self.requestSenderProvider = requestSenderProvider
    }
    
    public func queryPortAndQueueServerVersion(timeout: TimeInterval) -> [Int: Version] {
        let group = DispatchGroup()
        
        let portToVersion = AtomicValue<[Int: Version]>([:])
        
        for port in portRange {
            group.enter()
            Logger.debug("Checking availability of \(port)")
            
            let queueServerVersionFetcher = QueueServerVersionFetcherImpl(
                requestSender: requestSenderProvider.requestSender(
                    socketAddress: SocketAddress(host: host, port: port)
                )
            )
            
            queueServerVersionFetcher.fetchQueueServerVersion(
                callbackQueue: workQueue
            ) { (result: Either<Version, Error>) in
                if let version = try? result.dematerialize() {
                    Logger.debug("Found queue server with \(version) version at \(port)")
                    portToVersion.withExclusiveAccess { $0[port] = version }
                }
                group.leave()
            }
        }
        
        _ = group.wait(timeout: .now() + timeout)
        return portToVersion.currentValue()
    }
}

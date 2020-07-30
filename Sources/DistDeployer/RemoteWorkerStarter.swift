import Deployer
import Foundation
import Logging
import PathLib
import ProcessController
import QueueModels
import SocketModels
import TemporaryStuff
import UniqueIdentifierGenerator

public protocol RemoteWorkerStarter {
    func deployAndStartWorker(
        queueAddress: SocketAddress
    ) throws
}

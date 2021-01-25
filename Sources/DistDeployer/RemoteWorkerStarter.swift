import SocketModels

public protocol RemoteWorkerStarter {
    func deployAndStartWorker(
        queueAddress: SocketAddress
    ) throws
}

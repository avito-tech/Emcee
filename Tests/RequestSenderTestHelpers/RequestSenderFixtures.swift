import Foundation
import RequestSender
import SocketModels

public final class RequestSenderFixtures {
    public static func localhostRequestSender(port: SocketModels.Port) -> RequestSender {
        return RequestSenderImpl(
            logger: .noOp,
            urlSession: URLSession(configuration: .default),
            queueServerAddress: SocketAddress(host: "localhost", port: port)
        )
    }
}

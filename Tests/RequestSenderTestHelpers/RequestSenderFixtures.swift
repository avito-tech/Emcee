import Foundation
import RequestSender
import Models

public final class RequestSenderFixtures {
    public static func localhostRequestSender(port: Models.Port) -> RequestSender {
        return RequestSenderImpl(
            urlSession: URLSession(configuration: .default),
            queueServerAddress: SocketAddress(host: "localhost", port: port)
        )
    }
}

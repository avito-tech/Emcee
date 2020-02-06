import RequestSender
import Models

class FakeNetworkRequest: NetworkRequest {
    typealias Payload = [String: String]
    typealias Response = [String: String]

    let httpMethod: HTTPMethod
    let payload: [String : String]?
    let pathWithLeadingSlash = "/"

    init(
        httpMethod: HTTPMethod = HTTPMethod.post,
        payload: [String : String]? = ["foo": "bar"]
    ) {
        self.httpMethod = httpMethod
        self.payload = payload
    }
}

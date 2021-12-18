import RESTInterfaces
import RequestSender

public final class WhatIsMyIpRequest: NetworkRequest {
    public typealias Response = WhatIsMyIpResponse

    public let httpMethod = HTTPMethod.post
    public let pathWithLeadingSlash = WhatIsMyIpRESTMethod().pathWithLeadingSlash

    public let payload: WhatIsMyIpPayload?
    public init(payload: WhatIsMyIpPayload) {
        self.payload = payload
    }
}

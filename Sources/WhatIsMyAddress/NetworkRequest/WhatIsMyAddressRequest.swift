import RESTInterfaces
import RequestSender

public final class WhatIsMyAddressRequest: NetworkRequest {
    public typealias Response = WhatIsMyAddressResponse

    public let httpMethod = HTTPMethod.post
    public let pathWithLeadingSlash = WhatIsMyAddressRESTMethod().pathWithLeadingSlash

    public let payload: WhatIsMyAddressPayload?
    public init(payload: WhatIsMyAddressPayload) {
        self.payload = payload
    }
}

import Foundation

//public extension HttpResponse {
//    private static let responseEncoder = JSONEncoder.pretty()
//    
//    static func json<R: Encodable>(response: R) -> HttpResponse {
//        do {
//            let data = try responseEncoder.encode(response)
//            return .raw(200, "OK", ["Content-Type": "application/json"]) { writer in
//                try writer.write(data)
//            }
//        } catch {
//            return .raw(500, "Error", ["Content-Type": "application/json"]) { writer in
//                try writer.write(
//                    responseEncoder.encode(
//                        [
//                            "error": "\(error)",
//                            "operationDescription": "Failed to generate JSON response"
//                        ]
//                    )
//                )
//            }
//        }
//    }
//}

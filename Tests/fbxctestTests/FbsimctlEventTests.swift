import Foundation
import XCTest
import fbxctest

final class FF: XCTestCase {
    func test() throws {
        let string = """
        {"event_name":"create","timestamp":1572000651,"subject":{"name":"iPhone 7","arch":"x86_64","os":"iOS 11.3","container-pid":0,"model":"iPhone 7","udid":"8E381566-6E90-44F8-98D5-5A244B818667","state":"Shutdown","pid":0},"event_type":"ended"}
        """
        
        let data = string.data(using: .utf8)!
        
        let event = try JSONDecoder().decode(FbSimCtlCreateEndedEvent.self, from: data)
        
        XCTAssertEqual(
            event,
            FbSimCtlCreateEndedEvent(
                timestamp: 1572000651,
                subject: FbSimCtlCreateEndedEvent.Subject(
                    name: "iPhone 7",
                    arch: "x86_64",
                    os: "iOS 11.3",
                    model: "iPhone 7",
                    udid: "8E381566-6E90-44F8-98D5-5A244B818667"
                )
            )
        )
    }
}

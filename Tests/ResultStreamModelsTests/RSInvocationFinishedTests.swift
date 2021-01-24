import Foundation
import ResultStreamModels
import XCTest

final class RSInvocationFinishedTests: XCTestCase {
    func test() {
        let input = """
        {
            "_type": {
                "_name": "StreamedEvent"
            },
            "name": {
                "_type": {
                    "_name": "String"
                },
                "_value": "invocationFinished"
            },
            "structuredPayload": {
                "_type": {
                    "_name": "InvocationFinishedEventPayload",
                    "_supertype": {
                        "_name": "AnyStreamedEventPayload"
                    }
                },
                "recordRef": {
                    "_type": {
                        "_name": "Reference"
                    },
                    "id": {
                        "_type": {
                            "_name": "String"
                        },
                        "_value": "0~YDSu...5QgHr3cdQ=="
                    },
                    "targetType": {
                        "_type": {
                            "_name": "TypeDefinition"
                        },
                        "name": {
                            "_type": {
                                "_name": "String"
                            },
                            "_value": "ActionsInvocationRecord"
                        }
                    }
                }
            }
        }
        """
        
        check(
            input: input,
            equals: RSInvocationFinished(
                structuredPayload: RSInvocationFinishedEventPayload(
                    recordRef: RSReference(id: "0~YDSu...5QgHr3cdQ==")
                )
            )
        )
    }
}


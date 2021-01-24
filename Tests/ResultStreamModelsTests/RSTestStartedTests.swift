import Foundation
import ResultStreamModels
import XCTest

final class RSTestStartedTests: XCTestCase {
    func test() throws {
        let input = """
        {
            "_type": {
                "_name": "StreamedEvent"
            },
            "name": {
                "_type": {
                    "_name": "String"
                },
                "_value": "testStarted"
            },
            "structuredPayload": {
                "_type": {
                    "_name": "TestEventPayload",
                    "_supertype": {
                        "_name": "AnyStreamedEventPayload"
                    }
                },
                "resultInfo": {
                    "_type": {
                        "_name": "StreamedActionResultInfo"
                    },
                    "resultIndex": {
                        "_type": {
                            "_name": "Int"
                        },
                        "_value": "1"
                    }
                },
                "testIdentifier": {
                    "_type": {
                        "_name": "ActionTestSummaryIdentifiableObject",
                        "_supertype": {
                            "_name": "ActionAbstractTestSummary"
                        }
                    },
                    "identifier": {
                        "_type": {
                            "_name": "String"
                        },
                        "_value": "ClassName/test_method()"
                    },
                    "name": {
                        "_type": {
                            "_name": "String"
                        },
                        "_value": "test_method()"
                    }
                }
            }
        }
        """
        
        check(
            input: input,
            equals: RSTestStarted(
                structuredPayload: RSTestEventPayload(
                    resultInfo: RSStreamedActionResultInfo(resultIndex: 1),
                    testIdentifier: RSActionTestSummaryIdentifiableObject(
                        identifier: "ClassName/test_method()",
                        name: "test_method()"
                    )
                )
            )
        )
    }
}

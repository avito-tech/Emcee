import Foundation
import ResultStreamModels
import XCTest

final class RSTestSuiteStartedTests: XCTestCase {
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
                "_value": "testSuiteStarted"
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
                        "_name": "ActionTestSummaryGroup",
                        "_supertype": {
                            "_name": "ActionTestSummaryIdentifiableObject",
                            "_supertype": {
                                "_name": "ActionAbstractTestSummary"
                            }
                        }
                    },
                    "identifier": {
                        "_type": {
                            "_name": "String"
                        },
                        "_value": "ClassName (id)"
                    },
                    "name": {
                        "_type": {
                            "_name": "String"
                        },
                        "_value": "ClassName (name)"
                    }
                }
            }
        }
        """
        
        check(
            input: input,
            equals: RSTestSuiteStarted(
                structuredPayload: RSTestEventPayload(
                    resultInfo: RSStreamedActionResultInfo(resultIndex: 1),
                    testIdentifier: ActionTestSummaryGroup(
                        identifier: "ClassName (id)",
                        name: "ClassName (name)",
                        duration: nil,
                        subtests: nil
                    )
                )
            )
        )
    }
}


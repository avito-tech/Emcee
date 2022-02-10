import CommonTestModels
import Foundation

public enum RSTestStartedTestInput {
    public static func input(testName: TestName) -> String {
      """
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
                        "_value": "\(testName.className)/\(testName.methodName)()"
                    },
                    "name": {
                        "_type": {
                            "_name": "String"
                        },
                        "_value": "\(testName.methodName)()"
                    }
                }
            }
        }
    """
    }
}

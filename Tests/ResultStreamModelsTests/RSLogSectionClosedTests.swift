import Foundation
import ResultStreamModels
import XCTest

final class RSLogSectionClosedTests: XCTestCase {
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
                "_value": "logSectionClosed"
            },
            "structuredPayload": {
                "_type": {
                    "_name": "LogSectionClosedEventPayload",
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
                "sectionIndex": {
                    "_type": {
                        "_name": "Int"
                    },
                    "_value": "3"
                },
                "tail": {
                    "_type": {
                        "_name": "ActivityLogCommandInvocationSectionTail",
                        "_supertype": {
                            "_name": "ActivityLogSectionTail"
                        }
                    },
                    "duration": {
                        "_type": {
                            "_name": "Double"
                        },
                        "_value": "8.7e-05"
                    },
                    "result": {
                        "_type": {
                            "_name": "String"
                        },
                        "_value": "succeeded"
                    }
                }
            }
        }
        """
        
        check(
            input: input,
            equals: RSLogSectionClosed(
                structuredPayload: RSLogSectionClosedEventPayload(
                    sectionIndex: 3,
                    resultInfo: RSStreamedActionResultInfo(resultIndex: 1),
                    tail: RSActivityLogCommandInvocationSectionTail(
                        duration: 0.000087,
                        result: "succeeded"
                    )
                )
            )
        )
    }
}


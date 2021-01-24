import Foundation
import ResultStreamModels
import XCTest

final class RSLogSectionAttachedTests: XCTestCase {
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
                "_value": "logSectionAttached"
            },
            "structuredPayload": {
                "_type": {
                    "_name": "LogSectionAttachedEventPayload",
                    "_supertype": {
                        "_name": "AnyStreamedEventPayload"
                    }
                },
                "childSectionIndex": {
                    "_type": {
                        "_name": "Int"
                    },
                    "_value": "1"
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
                }
            }
        }
        """
        
        check(
            input: input,
            equals: RSLogSectionAttached(
                structuredPayload: RSLogSectionAttachedEventPayload(
                    childSectionIndex: 1,
                    resultInfo: RSStreamedActionResultInfo(
                        resultIndex: 1
                    )
                )
            )
        )
    }
}


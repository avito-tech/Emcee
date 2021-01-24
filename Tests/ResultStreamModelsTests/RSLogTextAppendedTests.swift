import Foundation
import ResultStreamModels
import XCTest

final class RSLogTextAppendedTests: XCTestCase {
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
                "_value": "logTextAppended"
            },
            "structuredPayload": {
                "_type": {
                    "_name": "LogTextAppendedEventPayload",
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
                    "_value": "5"
                },
                "text": {
                    "_type": {
                        "_name": "String"
                    },
                    "_value": "text"
                }
            }
        }
        """
        
        check(
            input: input,
            equals: RSLogTextAppended(
                structuredPayload: RSLogTextAppendedEventPayload(
                    text: "text",
                    resultInfo: RSStreamedActionResultInfo(resultIndex: 1),
                    sectionIndex: 5
                )
            )
        )
    }
}

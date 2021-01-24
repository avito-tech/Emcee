import Foundation
import ResultStreamModels
import XCTest

final class RSLogMessageEmittedTests: XCTestCase {
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
                "_value": "logMessageEmitted"
            },
            "structuredPayload": {
                "_type": {
                    "_name": "LogMessageEmittedEventPayload",
                    "_supertype": {
                        "_name": "AnyStreamedEventPayload"
                    }
                },
                "message": {
                    "_type": {
                        "_name": "ActivityLogMessage"
                    },
                    "location": {
                        "_type": {
                            "_name": "DocumentLocation"
                        },
                        "concreteTypeName": {
                            "_type": {
                                "_name": "String"
                            },
                            "_value": "DVTTextDocumentLocation"
                        },
                        "url": {
                            "_type": {
                                "_name": "String"
                            },
                            "_value": "file:///Users/url"
                        }
                    },
                    "shortTitle": {
                        "_type": {
                            "_name": "String"
                        },
                        "_value": "short"
                    },
                    "title": {
                        "_type": {
                            "_name": "String"
                        },
                        "_value": "title"
                    },
                    "type": {
                        "_type": {
                            "_name": "String"
                        },
                        "_value": "notice"
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
                }
            }
        }
        """
        
        check(
            input: input,
            equals: RSLogMessageEmitted(
                structuredPayload: RSLogMessageEmittedEventPayload(
                    message: RSActivityLogMessage(
                        shortTitle: "short",
                        title: "title",
                        type: "notice"
                    ),
                    sectionIndex: 3,
                    resultInfo: RSStreamedActionResultInfo(resultIndex: 1)
                )
            )
        )
    }
}

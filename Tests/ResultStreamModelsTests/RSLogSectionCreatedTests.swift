import Foundation
import ResultStreamModels
import XCTest

final class RSLogSectionCreatedTests: XCTestCase {
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
                "_value": "logSectionCreated"
            },
            "structuredPayload": {
                "_type": {
                    "_name": "LogSectionCreatedEventPayload",
                    "_supertype": {
                        "_name": "AnyStreamedEventPayload"
                    }
                },
                "head": {
                    "_type": {
                        "_name": "ActivityLogSectionHead"
                    },
                    "domainType": {
                        "_type": {
                            "_name": "String"
                        },
                        "_value": "com.apple.dt.unit.cocoaUnitTest"
                    },
                    "startTime": {
                        "_type": {
                            "_name": "Date"
                        },
                        "_value": "2020-12-22T18:51:50.000+0300"
                    },
                    "title": {
                        "_type": {
                            "_name": "String"
                        },
                        "_value": "Test Transient Testing"
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
                    "_value": "1"
                }
            }
        }
        """
        
        check(
            input: input,
            equals: RSLogSectionCreated(
                structuredPayload: RSLogSectionCreatedEventPayload(
                    head: RSActivityLogSectionHead(
                        domainType: "com.apple.dt.unit.cocoaUnitTest",
                        startTime: try RSDate("2020-12-22T18:51:50.000+0300"),
                        title: "Test Transient Testing"
                    ),
                    resultInfo: RSStreamedActionResultInfo(resultIndex: 1),
                    sectionIndex: 1
                )
            )
        )
    }
}

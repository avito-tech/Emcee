import Foundation
import ResultStreamModels
import XCTest

final class RSIssueEmittedTests: XCTestCase {
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
                "_value": "issueEmitted"
            },
            "structuredPayload": {
                "_type": {
                    "_name": "IssueEmittedEventPayload",
                    "_supertype": {
                        "_name": "AnyStreamedEventPayload"
                    }
                },
                "issue": {
                    "_type": {
                        "_name": "TestFailureIssueSummary",
                        "_supertype": {
                            "_name": "IssueSummary"
                        }
                    },
                    "documentLocationInCreatingWorkspace": {
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
                            "_value": "file:///file.swift#CharacterRangeLen=0&EndingLineNumber=60&StartingLineNumber=60"
                        }
                    },
                    "issueType": {
                        "_type": {
                            "_name": "String"
                        },
                        "_value": "Uncategorized"
                    },
                    "message": {
                        "_type": {
                            "_name": "String"
                        },
                        "_value": "message"
                    },
                    "testCaseName": {
                        "_type": {
                            "_name": "String"
                        },
                        "_value": "Class.test()"
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
                "severity": {
                    "_type": {
                        "_name": "String"
                    },
                    "_value": "testFailure"
                }
            }
        }

        """
        
        check(
            input: input,
            equals: RSIssueEmitted(
                structuredPayload: RSIssueEmittedEventPayload(
                    issue: RSTestFailureIssueSummary(
                        documentLocationInCreatingWorkspace: RSDocumentLocation(
                            concreteTypeName: "DVTTextDocumentLocation",
                            url: "file:///file.swift#CharacterRangeLen=0&EndingLineNumber=60&StartingLineNumber=60"
                        ),
                        issueType: "Uncategorized",
                        message: "message",
                        testCaseName: "Class.test()"
                    ),
                    resultInfo: RSStreamedActionResultInfo(resultIndex: 1),
                    severity: "testFailure"
                )
            )
        )
    }
}

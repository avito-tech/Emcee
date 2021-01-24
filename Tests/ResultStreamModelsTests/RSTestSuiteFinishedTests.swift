import Foundation
import ResultStreamModels
import XCTest

final class RSTestSuiteFinishedTests: XCTestCase {
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
                "_value": "testSuiteFinished"
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
                    "duration": {
                        "_type": {
                            "_name": "Double"
                        },
                        "_value": "26.189553022384644"
                    },
                    "identifier": {
                        "_type": {
                            "_name": "String"
                        },
                        "_value": "Class"
                    },
                    "name": {
                        "_type": {
                            "_name": "String"
                        },
                        "_value": "Class"
                    },
                    "subtests": {
                        "_type": {
                            "_name": "Array"
                        },
                        "_values": [
                            {
                                "_type": {
                                    "_name": "ActionTestMetadata",
                                    "_supertype": {
                                        "_name": "ActionTestSummaryIdentifiableObject",
                                        "_supertype": {
                                            "_name": "ActionAbstractTestSummary"
                                        }
                                    }
                                },
                                "duration": {
                                    "_type": {
                                        "_name": "Double"
                                    },
                                    "_value": "26.187721014022827"
                                },
                                "identifier": {
                                    "_type": {
                                        "_name": "String"
                                    },
                                    "_value": "Class/test()"
                                },
                                "name": {
                                    "_type": {
                                        "_name": "String"
                                    },
                                    "_value": "test()"
                                },
                                "summaryRef": {
                                    "_type": {
                                        "_name": "Reference"
                                    },
                                    "id": {
                                        "_type": {
                                            "_name": "String"
                                        },
                                        "_value": "0~6Bl6_...unxI8M_fSA=="
                                    }
                                },
                                "testStatus": {
                                    "_type": {
                                        "_name": "String"
                                    },
                                    "_value": "Failure"
                                }
                            }
                        ]
                    }
                }
            }
        }


        """
        
        check(
            input: input,
            equals: RSTestSuiteFinished(
                structuredPayload: RSTestEventPayload(
                    resultInfo: RSStreamedActionResultInfo(resultIndex: 1),
                    testIdentifier: ActionTestSummaryGroup(
                        identifier: "Class",
                        name: "Class",
                        duration: 26.189553022384644,
                        subtests: [
                            RSActionTestMetadata(
                                identifier: "Class/test()",
                                name: "test()",
                                duration: 26.187721014022827,
                                testStatus: "Failure",
                                summaryRef: RSReference(id: "0~6Bl6_...unxI8M_fSA==")
                            )
                        ]
                    )
                )
            )
        )
    }
}


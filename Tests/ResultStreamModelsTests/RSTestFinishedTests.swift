import Foundation
import ResultStreamModels
import XCTest

final class RSTestFinishedTests: XCTestCase {
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
                "_value": "testFinished"
            },
            "structuredPayload": {
                "_type": {
                    "_name": "TestFinishedEventPayload",
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
                "test": {
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
                        "_value": "0.4511209726333618"
                    },
                    "identifier": {
                        "_type": {
                            "_name": "String"
                        },
                        "_value": "Class/test_method()"
                    },
                    "name": {
                        "_type": {
                            "_name": "String"
                        },
                        "_value": "test_method()"
                    },
                    "summaryRef": {
                        "_type": {
                            "_name": "Reference"
                        },
                        "id": {
                            "_type": {
                                "_name": "String"
                            },
                            "_value": "0~KoM-3hFhytatzzwh8deD529-qhF5gV6ZZj07V3Q8QLaOtATsXAIIVzN7-YGYn_cWdeQ-wvygheYaJ8qEaneYuQ=="
                        },
                        "targetType": {
                            "_type": {
                                "_name": "TypeDefinition"
                            },
                            "name": {
                                "_type": {
                                    "_name": "String"
                                },
                                "_value": "ActionTestSummary"
                            },
                            "supertype": {
                                "_type": {
                                    "_name": "TypeDefinition"
                                },
                                "name": {
                                    "_type": {
                                        "_name": "String"
                                    },
                                    "_value": "ActionTestSummaryIdentifiableObject"
                                },
                                "supertype": {
                                    "_type": {
                                        "_name": "TypeDefinition"
                                    },
                                    "name": {
                                        "_type": {
                                            "_name": "String"
                                        },
                                        "_value": "ActionAbstractTestSummary"
                                    }
                                }
                            }
                        }
                    },
                    "testStatus": {
                        "_type": {
                            "_name": "String"
                        },
                        "_value": "Success"
                    }
                }
            }
        }
        """
        
        check(
            input: input,
            equals: RSTestFinished(
                structuredPayload: RSTestFinishedEventPayload(
                    resultInfo: RSStreamedActionResultInfo(resultIndex: 1),
                    test: RSActionTestMetadata(
                        identifier: "Class/test_method()",
                        name: "test_method()",
                        duration: 0.4511209726333618,
                        testStatus: "Success",
                        summaryRef: RSReference(id: "0~KoM-3hFhytatzzwh8deD529-qhF5gV6ZZj07V3Q8QLaOtATsXAIIVzN7-YGYn_cWdeQ-wvygheYaJ8qEaneYuQ==")
                    )
                )
            )
        )
    }
}

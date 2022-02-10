import CommonTestModels
import Foundation

public enum RSTestFinishedTestInput {
    public static func input(testName: TestName, duration: Double) -> String {
        """
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
                        "_value": "\(duration)"
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
                    },
                    "summaryRef": {
                        "_type": {
                            "_name": "Reference"
                        },
                        "id": {
                            "_type": {
                                "_name": "String"
                            },
                            "_value": "0~KoM-3hFhyt...aneYuQ=="
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
    }
}

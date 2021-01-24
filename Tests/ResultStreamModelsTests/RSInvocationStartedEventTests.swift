import Foundation
import ResultStreamModels
import XCTest

final class RSInvocationStartedEventTests: XCTestCase {
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
                "_value": "invocationStarted"
            },
            "structuredPayload": {
                "_type": {
                    "_name": "InvocationStartedEventPayload",
                    "_supertype": {
                        "_name": "AnyStreamedEventPayload"
                    }
                },
                "metadata": {
                    "_type": {
                        "_name": "ActionsInvocationMetadata"
                    },
                    "creatingWorkspaceFilePath": {
                        "_type": {
                            "_name": "String"
                        },
                        "_value": "/path/to/temporary.xcworkspace"
                    },
                    "schemeIdentifier": {
                        "_type": {
                            "_name": "EntityIdentifier"
                        },
                        "containerName": {
                            "_type": {
                                "_name": "String"
                            },
                            "_value": "temporary Workspace"
                        },
                        "entityName": {
                            "_type": {
                                "_name": "String"
                            },
                            "_value": "Transient Testing"
                        },
                        "entityType": {
                            "_type": {
                                "_name": "String"
                            },
                            "_value": "scheme"
                        },
                        "sharedState": {
                            "_type": {
                                "_name": "String"
                            },
                            "_value": "unshared"
                        }
                    },
                    "uniqueIdentifier": {
                        "_type": {
                            "_name": "String"
                        },
                        "_value": "14D59414-6D81-44D3-9AD7-4C1D4BA134BA"
                    }
                }
            }
        }
        """
        
        check(
            input: input,
            equals: RSInvocationStarted(
                structuredPayload: RSInvocationStartedEventPayload(
                    metadata: RSActionsInvocationMetadata(
                        creatingWorkspaceFilePath: "/path/to/temporary.xcworkspace",
                        schemeIdentifier: RSEntityIdentifier(
                            containerName: "temporary Workspace",
                            entityName: "Transient Testing",
                            entityType: "scheme",
                            sharedState: "unshared"
                        ),
                        uniqueIdentifier: "14D59414-6D81-44D3-9AD7-4C1D4BA134BA"
                    )
                )
            )
        )
    }
}

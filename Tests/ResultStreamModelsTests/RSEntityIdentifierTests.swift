import Foundation
import ResultStreamModels
import TestHelpers
import XCTest

final class RSEntityIdentifierTests: XCTestCase {
    func test() {
        let input = """
        {
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
        }
        """
        
        check(
            input: input,
            equals: RSEntityIdentifier(
                containerName: "temporary Workspace",
                entityName: "Transient Testing",
                entityType: "scheme",
                sharedState: "unshared"
            )
        )
    }
}


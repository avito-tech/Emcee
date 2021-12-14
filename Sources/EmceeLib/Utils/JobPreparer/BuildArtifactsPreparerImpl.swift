import BuildArtifacts
import EmceeLogging
import Foundation
import PathLib
import ResourceLocation
import TypedResourceLocation

public final class BuildArtifactsPreparerImpl: BuildArtifactsPreparer {
    private let localTypedResourceLocationPreparer: LocalTypedResourceLocationPreparer
    private let logger: ContextualLogger
    
    public init(
        localTypedResourceLocationPreparer: LocalTypedResourceLocationPreparer,
        logger: ContextualLogger
    ) {
        self.localTypedResourceLocationPreparer = localTypedResourceLocationPreparer
        self.logger = logger
    }
    
    public func prepare(buildArtifacts: IosBuildArtifacts) throws -> IosBuildArtifacts {
        try remotelyAccessibleBuildArtifacts(buildArtifacts: buildArtifacts)
    }
    
    private func remotelyAccessibleBuildArtifacts(
        buildArtifacts: IosBuildArtifacts
    ) throws -> IosBuildArtifacts {
        let remotelyAccessibleTestBundle = XcTestBundle(
            location: try localTypedResourceLocationPreparer.generateRemotelyAccessibleTypedResourceLocation(buildArtifacts.xcTestBundle.location),
            testDiscoveryMode: buildArtifacts.xcTestBundle.testDiscoveryMode
        )
        
        switch buildArtifacts {
        case .iosLogicTests:
            return .iosLogicTests(
                xcTestBundle: remotelyAccessibleTestBundle
            )
        case .iosApplicationTests(_, let appBundle):
            return .iosApplicationTests(
                xcTestBundle: remotelyAccessibleTestBundle,
                appBundle: try localTypedResourceLocationPreparer.generateRemotelyAccessibleTypedResourceLocation(appBundle)
            )
        case .iosUiTests(_, let appBundle, let runner, let additionalApplicationBundles):
            return .iosUiTests(
                xcTestBundle: remotelyAccessibleTestBundle,
                appBundle: try localTypedResourceLocationPreparer.generateRemotelyAccessibleTypedResourceLocation(appBundle),
                runner: try localTypedResourceLocationPreparer.generateRemotelyAccessibleTypedResourceLocation(runner),
                additionalApplicationBundles: try additionalApplicationBundles.map {
                    try localTypedResourceLocationPreparer.generateRemotelyAccessibleTypedResourceLocation($0)
                }
            )
        }
    }
}

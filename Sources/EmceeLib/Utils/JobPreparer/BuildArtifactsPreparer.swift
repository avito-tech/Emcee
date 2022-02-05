import BuildArtifacts
import Foundation

public protocol BuildArtifactsPreparer {
    func prepare(buildArtifacts: AppleBuildArtifacts) throws -> AppleBuildArtifacts
}

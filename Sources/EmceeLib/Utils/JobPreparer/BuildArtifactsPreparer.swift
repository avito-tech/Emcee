import BuildArtifacts
import Foundation

public protocol BuildArtifactsPreparer {
    func prepare(buildArtifacts: IosBuildArtifacts) throws -> IosBuildArtifacts
}

import BuildArtifacts
import Foundation

public protocol BuildArtifactsPreparer {
    func prepare(buildArtifacts: BuildArtifacts) throws -> BuildArtifacts
}

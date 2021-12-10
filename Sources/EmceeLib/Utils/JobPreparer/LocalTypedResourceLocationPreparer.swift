import Foundation
import TypedResourceLocation

public protocol LocalTypedResourceLocationPreparer {
    
    /// If provided `TypedResourceLocation` refers to a local file, it will be translated into a remotely accessible resource location.
    func generateRemotelyAccessibleTypedResourceLocation<T: ResourceLocationType>(
        _ from: TypedResourceLocation<T>
    ) throws -> TypedResourceLocation<T>
}

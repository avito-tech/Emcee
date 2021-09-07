public enum XcTestRunAttachmentLifetime: String {
    
    /// Attachments enabled, but will be deleted for success tests
    case deleteOnSuccess
    
    /// Attachments enabled
    case keepAlways
    
    /// Attachments disabled
    case keepNever
}

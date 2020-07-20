import Foundation
import Types

/// Unique Device Id - both for simulators and real devices
///
/// Even though Apple uses UUID-like string to represent simulator and device id, we use `String`
/// - to preserve case sensivity information
/// - in case if Apple changes the structure of device ID
public final class UDID: NewStringType {}

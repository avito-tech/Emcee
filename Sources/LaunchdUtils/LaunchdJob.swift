import Foundation

public final class LaunchdJob {
    public enum InetdCompatibility {
        /** Simulation is disabled */
        case disabled
        /** "wait" option of inetd: the listening socket is passed via the stdio file descriptors */
        case enabledWithWait
        /** "nowait" option of inetd: accept is called on behalf of the job, and the result is passed via the stdio descriptors */
        case enabledWithoutWait
    }
    
    public enum LoadSessionType: String {
        /** Has access to all GUI services; much like a login item. This is a default value. */
        case aqua = "Aqua"
        /** Runs only in non-GUI login sessions (most notably, SSH login sessions) */
        case standardIO = "StandardIO"
        /** Runs in a context that's the parent of all contexts for a given user */
        case background = "Background"
        /** Runs in the loginwindow context */
        case loginWindow = "LoginWindow"
    }
    
    /** Unique reverse DNS name of the job */
    let label: String
    /** What to invoke: ['ls', '-la', '/Applications'] */
    let programArguments: [String]
    /** Environment of the program being executed */
    let environmentVariables: [String: String]
    /** Working directory */
    let workingDirectory: String
    /** Should the job be started by launchd when it loads it */
    let runAtLoad: Bool
    /** Indicates if job is enabled or disabled. You still can force load it. */
    let disabled: Bool
    /** Where to redirect stdout */
    let standardOutRedirectionPath: String?
    /** Where to redirect stderr */
    let standardErrorRedirectionPath: String?
    /** All exposed sockets. Key is your id of the socket, e.g. "sock1". */
    let sockets: [String: LaunchdSocket]
    /** Simulate inetd-like operation */
    let inetdCompatibility: InetdCompatibility
    /** Specifies a particular session type to run your agent in. Default is Aqua. */
    let sessionType: LoadSessionType

    public init(
        label: String,
        programArguments: [String],
        environmentVariables: [String: String],
        workingDirectory: String,
        runAtLoad: Bool,
        disabled: Bool,
        standardOutPath: String?,
        standardErrorPath: String?,
        sockets: [String: LaunchdSocket],
        inetdCompatibility: InetdCompatibility,
        sessionType: LoadSessionType)
    {
        self.label = label
        self.programArguments = programArguments
        self.environmentVariables = environmentVariables
        self.workingDirectory = workingDirectory
        self.runAtLoad = runAtLoad
        self.disabled = disabled
        self.standardOutRedirectionPath = standardOutPath
        self.standardErrorRedirectionPath = standardErrorPath
        self.sockets = sockets
        self.inetdCompatibility = inetdCompatibility
        self.sessionType = sessionType
    }
}

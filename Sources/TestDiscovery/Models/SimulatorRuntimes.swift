import PathLib

struct SimulatorRuntimes: Decodable {
    struct Runtime: Decodable {
        let bundlePath: AbsolutePath
        let identifier: String
    }
    
    let runtimes: [Runtime]
}

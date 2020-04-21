import PathLib

struct SimulatorRuntimes: Decodable {
    struct Runtime: Decodable {
        let bundlePath: AbsolutePath
        let name: String
    }
    
    let runtimes: [Runtime]
}

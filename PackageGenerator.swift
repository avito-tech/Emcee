import Foundation

func log(_ text: String) {
    if ProcessInfo.processInfo.environment["DEBUG"] != nil {
        print(text)
    }
}

let knownImportsToIgnore = [
    "CSSH",
    "Darwin",
    "Dispatch",
    "Foundation",
    "XCTest",
]

let jsonEncoder = JSONEncoder()
jsonEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]

let importStatementExpression = try NSRegularExpression(
    pattern: "^(@testable )?import (.*)$",
    options: [.anchorsMatchLines]
)

struct ModuleDescription {
    let name: String
    let deps: [String]
    let path: String
    let isTest: Bool
}

func generate(at url: URL, isTestTarget: Bool) throws -> [ModuleDescription] {
    guard let enumerator = FileManager().enumerator(
        at: url,
        includingPropertiesForKeys: nil,
        options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles]
    ) else {
        print("Failed to create file enumerator for url '\(url)'")
        return []
    }
    
    var result = [ModuleDescription]()

    while let moduleFolderUrl = enumerator.nextObject() as? URL {
        let moduleEnumerator = FileManager().enumerator(
            at: moduleFolderUrl,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )
        let moduleName = moduleFolderUrl.lastPathComponent
        log("Analyzing \(moduleName)")
        
        var importedModuleNames = Set<String>()
        
        while let moduleFile = moduleEnumerator?.nextObject() as? URL {
            if ["md"].contains(moduleFile.pathExtension) {
                continue
            }
            log("    Analyzing \(moduleFile.lastPathComponent)")
            guard try moduleFile.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile == true else {
                log("    Skipping \(moduleFile.lastPathComponent): is not regular file")
                continue
            }
            let fileContents = try String(contentsOf: moduleFile)
                .split(separator: "\n")
                .filter { !$0.starts(with: "//") }
            for line in fileContents {
                let matches = importStatementExpression.matches(in: String(line), options: [], range: NSMakeRange(0, line.count))
                guard matches.count == 1 else {
                    continue
                }
                
                let importedModuleName = (line as NSString).substring(with: matches[0].range(at: 2))
                importedModuleNames.insert(importedModuleName)
            }
        }
        
        let path = moduleFolderUrl.path.dropFirst(moduleFolderUrl.deletingLastPathComponent().deletingLastPathComponent().path.count + 1)
        let dependencies = importedModuleNames.filter { !knownImportsToIgnore.contains($0) }.sorted()
        
        result.append(
            ModuleDescription(name: moduleName, deps: dependencies, path: String(path), isTest: isTestTarget)
        )
    }
    
    return result
}

func generatePackageSwift(raplacementForTargets: [String]) throws {
    log("Loading template")
    var templateContents = try String(contentsOf: URL(fileURLWithPath: "Package.swift.template"))
    templateContents = templateContents.replacingOccurrences(
        of: "<__TARGETS__>",
        with: raplacementForTargets.map { "        \($0)" }.joined(separator: "\n")
    )
    
    if ProcessInfo.processInfo.environment["ON_CI"] != nil {
        log("Checking for Package.swift consistency")
        let existingContents = try String(contentsOf: URL(fileURLWithPath: "Package.swift"))
        if existingContents != templateContents {
            fatalError("ON_CI is set, and Package.swift differs. Please update and commit Package.swift!")
        }
    }
    
    log("Saving Package.swift")
    try templateContents.write(to: URL(fileURLWithPath: "Package.swift"), atomically: true, encoding: .utf8)
}

func main() throws {
    var moduleDescriptions = [ModuleDescription]()
    moduleDescriptions.append(
        contentsOf: try generate(at: URL(fileURLWithPath: "Sources"), isTestTarget: false)
    )
    moduleDescriptions.append(
        contentsOf: try generate(at: URL(fileURLWithPath: "Tests"), isTestTarget: true)
    )
    
    var generatedTargetStatements = [String]()
    let sortedModuleDescriptions: [ModuleDescription] = moduleDescriptions.sorted { $0.name < $1.name }
    for moduleDescription in sortedModuleDescriptions {
        generatedTargetStatements.append(".\(!moduleDescription.isTest ? "target" : "testTarget")(")
        generatedTargetStatements.append("    // MARK: \(moduleDescription.name)")
        generatedTargetStatements.append("    name: " + "\"\(moduleDescription.name)\"" + ",")
        generatedTargetStatements.append("    dependencies: [")
        for dependency in moduleDescription.deps {
            generatedTargetStatements.append("        \"\(dependency)\",")
        }
        generatedTargetStatements.append("    ],")
        generatedTargetStatements.append("    path: " + "\"" + moduleDescription.path + "\"")
        generatedTargetStatements.append("),")
    }
    try generatePackageSwift(raplacementForTargets: generatedTargetStatements)
}

try main()

import PathLib
import TemporaryStuff
import Foundation

func createTestDataForEnumeration(tempFolder: TemporaryFolder) throws -> Set<AbsolutePath> {
    return Set([
        try tempFolder.createFile(filename: "root_file"),
        try tempFolder.pathByCreatingDirectories(components: ["empty_folder"]),
        try tempFolder.pathByCreatingDirectories(components: ["subfolder"]),
        try tempFolder.createFile(components: ["subfolder"], filename: "file_in_subfolder")
    ])
}

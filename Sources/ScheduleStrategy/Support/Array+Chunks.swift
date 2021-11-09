import Foundation

public extension Array {
    func splitToChunks(withSize chunkSize: UInt) -> [[Element]] {
        if chunkSize == 0 { return [self] }
        return stride(from: 0, to: self.count, by: Int(chunkSize)).map {
            Array(self[$0..<Swift.min($0 + Int(chunkSize), self.count)])
        }
    }
    
    func splitToChunks(count: UInt) -> [[Element]] {
        splitToChunks(withSize: Swift.max(1, UInt(self.count) / count))
    }
    
    func splitToVariableChunks(
        withStartingRelativeSize size: Double,
        changingRelativeSizeBy step: Double = 1.0,
        minimumRelativeSize: Double = 0.0,
        minimumChunkSize: UInt = 1
    ) -> [[Element]] {
        if size <= 0.0 || size >= 1.0 {
            fatalError("startingRelativeSize must be a number within (0.0, 1.0) range, but was given \(size)")
        }
        if step > 1.0 || step <= 0.0 {
            fatalError("step must be a number within (0.0, 1.0] range, but was given \(step)")
        }
        
        var chunks = [[Element]]()
        
        var relativeSize = size
        var position = 0
        while position < self.count {
            var size = Int(ceil(Double(self.count) * relativeSize))
            if size > minimumChunkSize {
                relativeSize = Swift.max(minimumRelativeSize, relativeSize * step)
            } else {
                size = Int(minimumChunkSize)
            }
            let toElementIndex = Swift.min(position + size, self.count)
            let subentries = Array(self[position ..< toElementIndex])
            position = toElementIndex
            
            chunks.append(subentries)
        }
        
        return chunks
    }
}

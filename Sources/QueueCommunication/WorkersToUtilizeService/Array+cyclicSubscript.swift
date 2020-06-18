extension Array {
    func cyclicSubscript(_ index: Int) -> Element {
        guard count != 0 else {
            fatalError("Failed: called cyclicSubscript on empty array")
        }
        
        return self[index % count]
    }
}

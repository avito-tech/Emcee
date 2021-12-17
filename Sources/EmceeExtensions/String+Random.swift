import Foundation

extension String {
    public static func randomString(length: Int) -> Self {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        
        var result = [Character]()
        
        for _ in 0..<length {
            if let char = letters.randomElement() {
                result.append(char)
            }
        }
        
        return Self(result)
    }
}

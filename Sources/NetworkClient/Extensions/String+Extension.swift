import Foundation

extension String {
    
    static var empty: String {
        ""
    }
    
    var sha256: String {
        if let stringData = self.data(using: String.Encoding.utf8) {
            return stringData.sha256()
        }
        return ""
    }
}

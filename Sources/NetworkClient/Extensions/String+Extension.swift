import Foundation

public extension String {
    static let empty = ""

    var sha256: String {
        if let stringData = data(using: String.Encoding.utf8) {
            return stringData.sha256()
        }
        return .empty
    }
}

import Foundation

private enum NetworkClientRetryHeader {
    static let key = "NetworkClient-Retry"
}

public extension URLRequest {
    
    var retryCount: Int {
        get {
            Int(value(forHTTPHeaderField: NetworkClientRetryHeader.key) ?? "") ?? 0
        }
        
        set {
            if newValue == 0 {
                setValue(nil, forHTTPHeaderField: NetworkClientRetryHeader.key)
            } else {
                setValue("\(newValue)", forHTTPHeaderField: NetworkClientRetryHeader.key)
            }
        }
    }
}

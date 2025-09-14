import Foundation

public enum NetworkCachePolicy {
    case cacheDuration(
        inGMT: TimeInterval,
        compareAndRemoveCacheWith: NetworkCachePolicyComparison
    )
    case persistent
    
    public enum NetworkCachePolicyComparison {
        case device(timestampInGMT: TimeInterval)
        case server(timestampInGMT: TimeInterval)
        
        var timestamp: TimeInterval {
            switch self {
            case .device(let deviceTimestamp): return deviceTimestamp
            case .server(let serverTimestamp): return serverTimestamp
            }
        }
    }
    
    var isCacheValid: Bool {
        switch self {
        case .cacheDuration(let duration, let comparison):
            let referenceTimestamp = comparison.timestamp
            let currentTimestamp = Date().timeIntervalSince1970
            let timeDifference = currentTimestamp - referenceTimestamp
            return timeDifference <= duration
        case .persistent:
            return true
        }
    }
}




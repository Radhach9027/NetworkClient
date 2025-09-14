import Foundation

public extension URLSessionConfiguration {
    static var defaultConfig: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.allowsCellularAccess = true
        configuration.timeoutIntervalForRequest = 5
        configuration.timeoutIntervalForResource = 5
        return configuration
    }
    
    static var intervalConfig: (_ timeoutIntervalForRequest: Double, _ timeoutIntervalForResource: Double) -> URLSessionConfiguration = { timeoutIntervalForRequest, timeoutIntervalForResource in
        let configuration = URLSessionConfiguration.default
        configuration.allowsCellularAccess = true
        configuration.timeoutIntervalForRequest = timeoutIntervalForRequest
        configuration.timeoutIntervalForResource = timeoutIntervalForResource
        return configuration
    }

    static var backgroundConfig: (String) -> URLSessionConfiguration = { identifier in
        let configuration = URLSessionConfiguration.background(withIdentifier: identifier)
        configuration.sessionSendsLaunchEvents = true
        configuration.allowsCellularAccess = true
        configuration.isDiscretionary = true
        configuration.sessionSendsLaunchEvents = true
        configuration.timeoutIntervalForRequest = 5
        configuration.timeoutIntervalForResource = 5
        return configuration
    }
    
    static var cache: URLSessionConfiguration {
        URLCache.shared.memoryCapacity = 512 * 1024 * 1024
        let configuration = URLSessionConfiguration.default
        configuration.allowsCellularAccess = true
        configuration.timeoutIntervalForRequest = 5
        configuration.timeoutIntervalForResource = 5
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        configuration.timeoutIntervalForRequest = 3000
        configuration.timeoutIntervalForResource = 3000
        return configuration
    }
}

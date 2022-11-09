import Foundation

extension URLSessionConfiguration {
    static var defaultConfig: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        return configuration
    }

    static var backgroundConfig: (String) -> URLSessionConfiguration = { identifier in
        let configuration = URLSessionConfiguration.background(withIdentifier: identifier)
        configuration.isDiscretionary = true
        configuration.sessionSendsLaunchEvents = true
        return configuration
    }
    
    static var cache: URLSessionConfiguration {
        URLCache.shared.memoryCapacity = 512 * 1024 * 1024
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        return configuration
    }
}

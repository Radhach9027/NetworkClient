import Foundation

extension URLSessionConfiguration {
    static var defaultConfig: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 30
        return configuration
    }

    static var backgroundConfig: (String) -> URLSessionConfiguration = { identifier in
        let configuration = URLSessionConfiguration.background(withIdentifier: identifier)
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 30
        configuration.isDiscretionary = true
        configuration.sessionSendsLaunchEvents = true
        return configuration
    }
}

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
}

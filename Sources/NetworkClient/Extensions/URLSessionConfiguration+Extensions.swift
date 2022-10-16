import Foundation

extension URLSessionConfiguration {
    
    static var defaultConfig: URLSessionConfiguration {
        URLSessionConfiguration.default
    }
    
    static var backgroundConfig: (String) -> URLSessionConfiguration  = { identifier in
        let configuration = URLSessionConfiguration.background(withIdentifier: identifier)
        configuration.isDiscretionary = true
        configuration.sessionSendsLaunchEvents = true
        return configuration
    }
}

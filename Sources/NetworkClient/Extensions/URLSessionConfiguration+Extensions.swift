import Foundation

extension URLSessionConfiguration {
    
    static var defaultConfig: URLSessionConfiguration {
        URLSessionConfiguration.default
    }
    
    static var backgroundConfig: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.background(withIdentifier: "MyBackgroundDownloader")
        configuration.isDiscretionary = true
        configuration.sessionSendsLaunchEvents = true
        return configuration
    }
}

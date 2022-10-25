import Foundation

extension URLSession {
    static func defaultSession(delegate: NetworkSessionDelegate) -> URLSession {
        URLSession(
            configuration: .defaultConfig,
            delegate: delegate,
            delegateQueue: nil
        )
    }

    static func backgroundSession(delegate: NetworkSessionDelegate, identifier: String) -> URLSession {
        URLSession(
            configuration: .backgroundConfig(identifier),
            delegate: delegate,
            delegateQueue: OperationQueue()
        )
    }
    
    static func ephemeralSession(delegate: NetworkSessionDelegate) -> URLSession {
        URLSession(
            configuration: .ephemeral,
            delegate: delegate,
            delegateQueue: nil
        )
    }
}

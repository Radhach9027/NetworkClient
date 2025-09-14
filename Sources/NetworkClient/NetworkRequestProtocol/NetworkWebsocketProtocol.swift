import Foundation

public enum SocketHeartBeat {
    case heartBeat(
        beatCount: Int,
        heartBeatSentTime: Int,
        isAutoSent: Bool,
        message: String
    )
}

public enum SocketAttachment {
    case attachment(
        status: String,
        identifier: String
    )
}

public protocol NetworkSocketRequestProtocol {
    var host: String? { get }
    var port: Int? { get }
    var identifier: String { get }
    var url: String? { get }
    var connectionTimeOut: Int { get }
    var reConnectionTimeOut: Int { get }
    var readTimedOut: Int { get }
    var heartBeat: SocketHeartBeat? { get }
    var socketAttachment: SocketAttachment? { get }
}

public extension NetworkSocketRequestProtocol {
    var host: String? {
        nil
    }

    var port: Int? {
        nil
    }

    var url: String? {
        nil
    }

    var connectionTimeOut: Int {
        10
    }

    var reConnectionTimeOut: Int {
        10
    }

    var readTimedOut: Int {
        30
    }
    
    var heartBeat: SocketHeartBeat? {
        nil
    }
    
    var socketAttachment: SocketAttachment? { 
        nil
    }
}

import Foundation

public enum SocketOperationType {
    case start
    case send
    case receive
    case cancel
}

public class SocketQueueManager {
    static let shared = SocketQueueManager()
    private var operationQueues: [SocketOperationType: DispatchQueue] = [:]

    private init() {}

    func getQueue(for operationType: SocketOperationType) -> DispatchQueue {
        if let existingQueue = operationQueues[operationType] {
            return existingQueue
        } else {
            let qos: DispatchQoS
            switch operationType {
            case .start:
                qos = .userInitiated
            case .send, .receive:
                qos = .default
            case .cancel:
                qos = .background
            }

            let newQueue = DispatchQueue(
                label: "com.network.\(operationType)",
                qos: qos,
                attributes: .concurrent
            )
            operationQueues[operationType] = newQueue
            return newQueue
        }
    }

    func removeQueue(for operationType: SocketOperationType) {
        operationQueues.removeValue(forKey: operationType)
    }

    func resetQueues() {
        operationQueues.removeAll()
    }
}



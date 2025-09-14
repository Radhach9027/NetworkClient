import Foundation
import os.lock

class RequestQueueManager {
    static let shared = RequestQueueManager()
    private var requestQueues: [String: OperationQueue] = [:]
    private var unfairLock = os_unfair_lock()

    private init() {}

    func getQueue(for requestIdentifier: String) -> OperationQueue {
        let normalizedIdentifier = normalizeIdentifier(requestIdentifier)

        os_unfair_lock_lock(&unfairLock)
        defer { os_unfair_lock_unlock(&unfairLock) }

        if let existingQueue = requestQueues[normalizedIdentifier] {
            return existingQueue
        } else {
            let newQueue = createOperationQueue(identifier: normalizedIdentifier)
            requestQueues[normalizedIdentifier] = newQueue
            return newQueue
        }
    }

    func removeQueue(for requestIdentifier: String) {
        let normalizedIdentifier = normalizeIdentifier(requestIdentifier)

        os_unfair_lock_lock(&unfairLock)
        defer { os_unfair_lock_unlock(&unfairLock) }

        requestQueues[normalizedIdentifier]?.cancelAllOperations()
        requestQueues.removeValue(forKey: normalizedIdentifier)
    }

    func resetQueues() {
        os_unfair_lock_lock(&unfairLock)
        defer { os_unfair_lock_unlock(&unfairLock) }

        for queue in requestQueues.values {
            queue.cancelAllOperations()
        }
        requestQueues.removeAll()
    }
}

private extension RequestQueueManager {
    func createOperationQueue(identifier: String) -> OperationQueue {
        let operationQueue = OperationQueue()
        operationQueue.name = "com.network.operationQueue.\(identifier)"
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }

    func normalizeIdentifier(_ identifier: String) -> String {
        return identifier
    }
}


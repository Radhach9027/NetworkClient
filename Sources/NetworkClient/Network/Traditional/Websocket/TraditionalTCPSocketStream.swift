import Foundation
import Network

@available(iOS 11.0, *)
public final class TraditionalTCPSocketStream: NSObject, WebSocketProtocol {
    private(set) var inputStream: InputStream?
    private(set) var outputStream: OutputStream?
    private var streamLock = os_unfair_lock_s()
    private let operationQueue = OperationQueue()
    
    public func start(
        for request: NetworkSocketRequestProtocol,
        completion: @escaping (Result<Bool, NetworkError>) -> Void
    ) {
        guard let host = request.host else {
            completion(.failure(.invalidHost))
            return
        }
        
        guard let port = request.port else {
            completion(.failure(.invalidPort))
            return
        }
        
        let operation = BlockOperation {
            os_unfair_lock_lock(&self.streamLock) // lock the critical section
            defer { os_unfair_lock_unlock(&self.streamLock) } // unlock after the operation
            
            Stream.getStreamsToHost(
                withName: host,
                port: port,
                inputStream: &self.inputStream,
                outputStream: &self.outputStream
            )
            
            guard let input = self.inputStream, let output = self.outputStream else {
                DispatchQueue.main.async {
                    completion(.failure(.socketStreamsFailure))
                }
                return
            }
            
            input.delegate = self
            output.delegate = self
            input.schedule(in: .current, forMode: .default)
            output.schedule(in: .current, forMode: .default)
            input.open()
            output.open()
            
            DispatchQueue.main.async {
                completion(.success(true))
            }
        }
        
        operationQueue.addOperation(operation) // Add operation to the queue
    }

    public func send(
        message: Data,
        completion: @escaping (Result<Bool, NetworkError>) -> Void
    ) {
        let operation = BlockOperation {
            os_unfair_lock_lock(&self.streamLock) // lock the critical section
            defer { os_unfair_lock_unlock(&self.streamLock) } // unlock after the operation
            
            guard let outputStream = self.outputStream else {
                completion(.failure(.socketStreamsOutputFailure))
                return
            }
            
            let bytesWritten = message.withUnsafeBytes { pointer in
                outputStream.write(pointer.bindMemory(to: UInt8.self).baseAddress!, maxLength: message.count)
            }

            if bytesWritten > 0 {
                completion(.success(true))
            } else {
                completion(.failure(.socketSendMessageFailure))
            }
        }
        
        operationQueue.addOperation(operation) // Add operation to the queue
    }

    public func receive(completion: @escaping (Result<Data, NetworkError>) -> Void) {
        let operation = BlockOperation {
            os_unfair_lock_lock(&self.streamLock) // lock the critical section
            defer { os_unfair_lock_unlock(&self.streamLock) } // unlock after the operation
            
            guard let inputStream = self.inputStream else {
                completion(.failure(.socketStreamsInputFailure))
                return
            }
            
            var buffer = [UInt8](repeating: 0, count: 1024)
            let bytesRead = inputStream.read(&buffer, maxLength: buffer.count)

            if bytesRead > 0 {
                let data = Data(buffer[0..<bytesRead])
                completion(.success(data))
            } else if bytesRead == 0 {
                completion(.failure(.socketStreamsClosed))
            } else {
                completion(.failure(.socketDataReadingFailure))
            }
        }
        
        operationQueue.addOperation(operation) // Add operation to the queue
    }

    public func cancel(completion: @escaping (Result<Bool, NetworkError>) -> Void) {
        let operation = BlockOperation {
            os_unfair_lock_lock(&self.streamLock) // lock the critical section
            defer { os_unfair_lock_unlock(&self.streamLock) } // unlock after the operation
            
            self.inputStream?.close()
            self.outputStream?.close()
            self.inputStream = nil
            self.outputStream = nil
            completion(.success(true))
        }
        
        operationQueue.addOperation(operation) // Add operation to the queue
    }
}

@available(iOS 11.0, *)
extension TraditionalTCPSocketStream: StreamDelegate {
    public func stream(
        _ aStream: Stream,
        handle eventCode: Stream.Event
    ) {
        os_unfair_lock_lock(&self.streamLock) // lock the critical section
        defer { os_unfair_lock_unlock(&self.streamLock) } // unlock after the operation

        switch eventCode {
        case .hasBytesAvailable:
            if aStream == inputStream {
                receive { result in
                    switch result {
                    case .success(let data):
                        // Handle received data
                        print("Data received: \(data)")
                    case .failure(let error):
                        print("Receive error: \(error)")
                    }
                }
            }

        case .hasSpaceAvailable:
            print("Output stream is ready to send data.")

        case .errorOccurred:
            print("Stream error occurred: \(String(describing: aStream.streamError?.localizedDescription))")
            cancel { result in
                if case .failure(let error) = result {
                    print("Cancel error: \(error)")
                }
            }

        case .endEncountered:
            print("Stream end encountered.")
            cancel { result in
                if case .failure(let error) = result {
                    print("End cancellation error: \(error)")
                }
            }

        default:
            break
        }
    }
}


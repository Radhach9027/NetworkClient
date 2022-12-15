import Combine
import Foundation

// MARK: Async download Tasks

@available(iOS 15.0, *)
public extension AsyncNetwork {
    func download(
        for request: NetworkDownloadRequestProtocol,
        receive: DispatchQueue
    ) async throws -> PassthroughSubject<NetworkDownloadResponse, NetworkError> {
        do {
            let url = try request.makeRequest().url
            let progress = Progress()
            try await withThrowingTaskGroup(of: Void.self) { group in
                progress.totalUnitCount = 1
                group.addTask {
                    let (url, _) = try await URLSession.shared.download(from: url!, progress: progress)
                    try? FileManager.default.removeItem(at: request.saveDownloadedUrlToLocation!)
                    try FileManager.default.moveItem(at: url, to: request.saveDownloadedUrlToLocation!)
                }
                try await group.waitForAll()
            }
            return delegate.downloadProgressSubject
        } catch let error as NSError {
            let failure = PassthroughSubject<NetworkDownloadResponse, NetworkError>()
            failure.send(completion: .failure(NetworkError.convertErrorToNetworkError(error: error)))
            return failure
        }
    }
}

enum OutputStreamError: Error {
    case writeFailure, bufferFailure
}

@available(iOS 15.0, *)
extension URLSession {
    func download(from url: URL, delegate: URLSessionTaskDelegate? = nil, progress parent: Progress) async throws -> (URL, URLResponse) {
        try await download(for: URLRequest(url: url), progress: parent)
    }

    func download(for request: URLRequest, delegate: URLSessionTaskDelegate? = nil, progress parent: Progress) async throws -> (URL, URLResponse) {
        let progress = Progress()
        parent.addChild(progress, withPendingUnitCount: 1)

        let bufferSize = 65536
        let estimatedSize: Int64 = 1000000

        let (asyncBytes, response) = try await bytes(for: request, delegate: delegate)
        let expectedLength = response.expectedContentLength // note, if server cannot provide expectedContentLength, this will be -1
        progress.totalUnitCount = expectedLength > 0 ? expectedLength : estimatedSize

        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
        guard let output = OutputStream(url: fileURL, append: false) else {
            throw URLError(.cannotOpenFile)
        }
        output.open()

        var buffer = Data()
        if expectedLength > 0 {
            buffer.reserveCapacity(min(bufferSize, Int(expectedLength)))
        } else {
            buffer.reserveCapacity(bufferSize)
        }

        var count: Int64 = 0
        for try await byte in asyncBytes {
            try Task.checkCancellation()

            count += 1
            buffer.append(byte)
            debugPrint("progress = \(progress)")

            if buffer.count >= bufferSize {
                try output.write(buffer)
                buffer.removeAll(keepingCapacity: true)

                if expectedLength < 0 || count > expectedLength {
                    progress.totalUnitCount = count + estimatedSize
                }
                progress.completedUnitCount = count
                debugPrint("progress completed = \(progress)")
            }
        }

        if !buffer.isEmpty {
            try output.write(buffer)
        }

        output.close()

        progress.totalUnitCount = count
        progress.completedUnitCount = count

        return (fileURL, response)
    }
}

extension OutputStream {
    func write(_ data: Data) throws {
        try data.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) throws in
            guard var pointer = buffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                throw OutputStreamError.bufferFailure
            }

            var bytesRemaining = buffer.count

            while bytesRemaining > 0 {
                let bytesWritten = write(pointer, maxLength: bytesRemaining)
                if bytesWritten < 0 {
                    throw OutputStreamError.writeFailure
                }

                bytesRemaining -= bytesWritten
                pointer += bytesWritten
            }
        }
    }
}

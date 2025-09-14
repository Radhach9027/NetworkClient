import Foundation

public enum NetworkUploadResponse {
    case progress(percentage: Float)
    case response(data: Data, loggerString: String)
}

public enum NetworkDownloadResponse {
    case progress(percentage: Float)
    case response(
        data: URL,
        loggerString: String,
        endPoint: NetworkDownloadRequestProtocol?
    )
}

public enum NetworkSocketMessage {
    case text(String)
    case data(Data)
}

public enum NetworkResultWithLogger<T, L> {
    case result(result: T, logger: L?)
}

public enum NetworkBulkDownloadResponse {
    case progress(percentage: Float)
    case response(data: URL, identifier: Int)
}

public enum NetworkSuccessResult<T> {
    case success(data: T, loggerString: String)
}

import Foundation

public enum NetworkUploadResponse {
    case progress(percentage: Float)
    case response(data: Data)
}

public enum NetworkDownloadResponse {
    case progress(percentage: Float)
    case response(data: URL)
}

public enum NetworkSocketMessage {
    case text(String)
    case data(Data)
}

public enum NetworkBulkDownloadResponse {
    case progress(percentage: Float)
    case response(data: URL, identifier: Int)
}

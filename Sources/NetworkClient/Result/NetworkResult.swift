import Foundation

public enum UploadNetworkResponse {
    case progress(percentage: Float)
    case response(data: Data)
}

public enum DownloadNetworkResponse {
    case progress(percentage: Float)
    case response(data: URL)
}

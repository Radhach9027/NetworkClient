import Foundation

public enum UploadNetworkResponse {
    case progress(percentage: Double)
    case response(data: Data?)
}

public enum DownloadNetworkResponse {
    case progress(percentage: Double)
    case response(data: URL?)
}

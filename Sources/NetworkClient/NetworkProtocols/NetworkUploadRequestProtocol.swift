import Foundation

public enum UploadFileFrom {
    case url(URL)
    case data(Data)
}

public protocol NetworkUploadRequestProtocol: NetworkRequestProtocol {
    var uploadFile: UploadFileFrom { get }
}

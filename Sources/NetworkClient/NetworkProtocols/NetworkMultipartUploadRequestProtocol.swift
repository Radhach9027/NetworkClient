import Foundation

public enum MultipartFormDataType {
    case form(name: String, value: String)
    case data(name: String, data: Data, mimeType: String)
}

public protocol NetworkMultipartUploadRequestProtocol: NetworkRequestProtocol {
    var boundary: String { get }
    var multipartFormDataType: MultipartFormDataType { get }
}

public extension NetworkMultipartUploadRequestProtocol {
    func makeRequest() throws -> URLRequest {
        guard let url = urlComponents?.url,
              url.isValid else {
            throw NetworkError.badUrl
        }

        var request = URLRequest(url: url)
        request.httpMethod = httpMethod.rawValue
        httpHeaderFields?.headers.forEach {
            request.setValue($0.value.description,
                             forHTTPHeaderField: $0.key.description)
        }
        request.httpBody = makeFormBody()
        guard let isReachableError = manageInternetConnectivityBasedOnCache(request: request) else {
            return request
        }

        throw isReachableError
    }
}

private extension NetworkMultipartUploadRequestProtocol {
    func makeFormBody() -> Data {
        switch multipartFormDataType {
        case let .data(name, data, mimeType):
            return dataFormField(
                name: name,
                data: data,
                mimeType: mimeType
            )
        case let .form(name, value):
            return textFormField(name: name, value: value)
        }
    }

    func textFormField(
        name: String,
        value: String
    ) -> Data {
        let fieldData = NSMutableData()
        var fieldString = "--\(boundary)\r\n"
        fieldString += "Content-Disposition: form-data; name=\"\(name)\"\r\n"
        fieldString += "Content-Type: text/plain; charset=ISO-8859-1\r\n"
        fieldString += "Content-Transfer-Encoding: 8bit\r\n"
        fieldString += "\r\n"
        fieldString += "\(value)\r\n"
        fieldData.append(fieldString)
        return fieldData as Data
    }

    func dataFormField(
        name: String,
        data: Data,
        mimeType: String
    ) -> Data {
        let fieldData = NSMutableData()
        fieldData.append("--\(boundary)\r\n")
        fieldData.append("Content-Disposition: form-data; name=\"\(name)\"\r\n")
        fieldData.append("Content-Type: \(mimeType)\r\n")
        fieldData.append("\r\n")
        fieldData.append(data)
        fieldData.append("\r\n")
        return fieldData as Data
    }
}

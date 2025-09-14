import Foundation

@available(iOS 11.0, *)
extension TraditionalNetwork {
    @discardableResult
    func logToConsole(
        request: URLRequest,
        response: URLResponse,
        requestStartTime: Date,
        responseTime: Date,
        responseData: Data?,
        isFromCache: Bool = false
    ) -> String {
        guard let httpResponse = response as? HTTPURLResponse else {
            return "❌ Failed to cast URLResponse to HTTPURLResponse."
        }

        let responseDuration = responseTime.timeIntervalSince(requestStartTime)
        
        let formattedDuration: String
        if responseDuration < 1 {
            let responseDurationInMilliseconds = responseDuration * 1000
            formattedDuration = String(format: "%.0fms", responseDurationInMilliseconds)
        } else if responseDuration < 60 {
            formattedDuration = String(format: "%.1fsec", responseDuration)
        } else {
            let responseDurationInMinutes = responseDuration / 60
            formattedDuration = String(format: "%.0fmin", responseDurationInMinutes)
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM, yyyy h:mma"
        let requestTimeFormatted = dateFormatter.string(from: requestStartTime)
        let responseTimeFormatted = dateFormatter.string(from: responseTime)

        var logMessage = "========== 🟢NETWORK CLIENT REQUEST START🟢 ==========\n"
        logMessage += "🎯 HTTP Status = \(httpResponse.statusCode)\n"
        logMessage += "🌍 Base URL = \(request.url?.absoluteString ?? "No URL")\n"
        logMessage += "🔍 Path = \(request.url?.relativePath ?? "No Path")\n"
        logMessage += "🔑 Path Params = \(request.url?.pathComponents.description ?? "No Path Components")\n"
        logMessage += "⚙️ HTTP Method = \(request.httpMethod ?? "No HTTP Method")\n"
        
        if let httpBody = request.httpBody {
            if let bodyString = String(data: httpBody, encoding: .utf8) {
                logMessage += "📝 HTTP Body = \(bodyString.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines))\n"
            } else {
                logMessage += "📝 HTTP Body could not be converted to string\n"
            }
        }
        logMessage += "🔁 Rerty Count = \(request.retryCount)\n"
        logMessage += "⏰ Request Time = \(requestTimeFormatted)\n"
        logMessage += "⏱️ Response Time = \(responseTimeFormatted)\n"
        logMessage += "⏳ Response Duration = \(formattedDuration)\n"
        logMessage += "⏳ Request Cached = \(isFromCache)\n"
        logMessage += "💬 Response = \(String(describing: httpResponse))\n"
        
        if let responseData = responseData {
            if let responseString = String(data: responseData, encoding: .utf8) {
                logMessage += "📦 Response Data = \(responseString.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines))\n"
            } else {
                logMessage += "📦 Response Data could not be converted to string.\n"
            }
        } else {
            logMessage += "📦 Response Data = No data received.\n"
        }
        
        logMessage += "\n========== 🟢NETWORK CLIENT REQUEST END🟢 ==========\n"
        consoleLogger?.logToConsole(logger: logMessage)
        return logMessage
    }
}

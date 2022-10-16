import Foundation

extension URLSessionTask {
    func resumeBackgroundTask() {
        self.earliestBeginDate = Date().addingTimeInterval(60 * 60)
        self.countOfBytesClientExpectsToSend = 200
        self.countOfBytesClientExpectsToReceive = 500 * 1024
        self.resume()
    }
}

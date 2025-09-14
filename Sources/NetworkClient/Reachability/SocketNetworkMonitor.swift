import Foundation
import Network

@available(iOS 12.0, *)
public class NetworkMonitor {
    static let shared = NetworkMonitor()
    private var monitor: NWPathMonitor?
    private let queue = DispatchQueue(label: "NetworkMonitorQueue")
    private init() {}

    // Flag to check if the internet is reachable
    public var isInternetReachable: Bool = true

    // Start monitoring network connectivity
    public func startMonitoring() {
        monitor = NWPathMonitor()
        monitor?.pathUpdateHandler = { path in
            self.isInternetReachable = (path.status == .satisfied)
            if !self.isInternetReachable {
                print("No internet connection available.")
            }
        }
        
        monitor?.start(queue: queue)
    }

    // Stop monitoring network connectivity
    public func stopMonitoring() {
        monitor?.cancel()
    }
}


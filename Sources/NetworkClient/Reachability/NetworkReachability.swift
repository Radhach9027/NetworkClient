import Foundation
import Network

public final class NetworkReachability {
    public enum ReachabilityStatus: Equatable {
        case connected
        case disconnected
    }
    
    // Weak reference to avoid strong retain cycles
    private class WeakObserver {
        weak var observer: AnyObject?
        
        init(observer: AnyObject) {
            self.observer = observer
        }
    }
    
    // Store weak references to observers
    private var reachabilityObservers: [WeakObserver] = []
    private(set) var reachabilityStatus: ReachabilityStatus = .connected
    public static let shared = NetworkReachability()
    private let monitor: NWPathMonitor
    private let queue: DispatchQueue
    
    private init() {
        monitor = NWPathMonitor()
        queue = DispatchQueue(label: "NetworkReachabilityQueue")
        startNotifier()
    }
    
    deinit {
        stopNotifier()
    }
    
    // Check if the device has an internet connection
    public var isReachable: Bool {
        return reachabilityStatus == .connected
    }
    
    // Check if the device is connected via Wi-Fi or Cellular
    public var isConnectedViaCellularOrWifi: Bool {
        return isConnectedViaCellular || isConnectedViaWiFi
    }
    
    // Check if the device is connected via cellular
    public var isConnectedViaCellular: Bool {
        return monitor.currentPath.usesInterfaceType(.cellular)
    }
    
    // Check if the device is connected via Wi-Fi
    public var isConnectedViaWiFi: Bool {
        return monitor.currentPath.usesInterfaceType(.wifi)
    }
    
    // Start monitoring the network status
    public func startNotifier() {
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                self.reachabilityStatus = .connected
            } else {
                self.reachabilityStatus = .disconnected
            }
            
            // Notify all active observers
            self.notifyObservers()
        }
        monitor.start(queue: queue)
    }
    
    // Stop monitoring the network status
    public func stopNotifier() {
        monitor.cancel()
    }
    
    // Add an observer
    public func addObserver(
        observer: AnyObject,
        observerBlock: @escaping (ReachabilityStatus) -> Void
    ) {
        let weakObserver = WeakObserver(observer: observer)
        reachabilityObservers.append(weakObserver)
        observerBlock(self.reachabilityStatus)
    }
    
    // Remove an observer (optional)
    public func removeObserver(_ observer: AnyObject) {
        reachabilityObservers.removeAll { weakObserver in
            weakObserver.observer === observer
        }
    }
    
    // Notify all observers
    private func notifyObservers() {
        // Clean up nil references
        reachabilityObservers = reachabilityObservers.filter { $0.observer != nil }
        
        // Notify all active observers
        for weakObserver in reachabilityObservers {
            guard let observer = weakObserver.observer else { continue }
            if let reachabilityObserver = observer as? ((ReachabilityStatus) -> Void) {
                reachabilityObserver(self.reachabilityStatus)
            }
        }
    }
}


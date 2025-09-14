import UIKit

public extension URL {
    var isValid: Bool {
        return (
            (self.host != nil)
            && (self.scheme != nil)
            && UIApplication.shared.canOpenURL(self))
    }
}

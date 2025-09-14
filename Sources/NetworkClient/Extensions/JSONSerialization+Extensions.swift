import Foundation

public extension Encodable {
    var toDictonary: [String: Any]? {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(self) else {
            print("Error encoding object.")
            return nil
        }

        guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) else {
            print("Error converting Data to JSON object.")
            return nil
        }

        return jsonObject as? [String: Any]
    }
}

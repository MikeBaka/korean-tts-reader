import Foundation
import AWSCore

enum Config {
    static func pollyRegion() -> AWSRegionType {
        return .USEast1
    }

    static func credentialProvider() -> AWSCredentialsProvider? {
}

// Helper to decode [String: Any]
struct AnyDecodable: Decodable {
    let value: Any

    init<T>(_ value: T?) {
        self.value = value ?? ()
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self.init(NSNull())
        } else if let bool = try? container.decode(Bool.self) {
            self.init(bool)
        } else if let int = try? container.decode(Int.self) {
            self.init(int)
        } else if let uint = try? container.decode(UInt.self) {
            self.init(uint)
        } else if let double = try? container.decode(Double.self) {
            self.init(double)
        } else if let string = try? container.decode(String.self) {
            self.init(string)
        } else if let array = try? container.decode([AnyDecodable].self) {
            self.init(array.map { $0.value })
        } else if let dictionary = try? container.decode([String: AnyDecodable].self) {
            self.init(dictionary.mapValues { $0.value })
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyDecodable value cannot be decoded")
        }
    }
}
        // region string may be nil – fall back to USEast1
        let regionStr = (cognitoIdentity["Default"] as? [String: Any])?["Region"] as? String

        let region: AWSRegionType = {
            switch (regionStr ?? "").lowercased() {
            case "us-west-2":      return .USWest2
            case "ap-northeast-2": return .APNortheast2
            default:               return .USEast1
            }
        }()

        return AWSCognitoCredentialsProvider(
            regionType:     region,
            identityPoolId: poolId
        )
    }

    // ── Fallback to environment variables ─────────────────────────────────

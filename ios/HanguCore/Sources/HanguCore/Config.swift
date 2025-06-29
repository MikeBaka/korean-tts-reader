import Foundation
import AWSCore

enum Config {
    static func pollyRegion() -> AWSRegionType {
        return .USEast1
    }

    static func credentialProvider() -> AWSCredentialsProvider? {
        // Check for awsconfiguration.json in the main bundle first.
        if let configPath = Bundle.main.path(forResource: "awsconfiguration", ofType: "json"),
           let configJson = try? Data(contentsOf: URL(fileURLWithPath: configPath)),
           let config = try? JSONDecoder().decode([String: AnyDecodable].self, from: configJson),
           let credentialsProviderConfig = config["CredentialsProvider"]?.value as? [String: Any],
           let cognitoIdentity = credentialsProviderConfig["CognitoIdentity"] as? [String: Any],
           let poolId = (cognitoIdentity["Default"] as? [String: Any])?["PoolId"] as? String,
           let regionStr = (cognitoIdentity["Default"] as? [String: Any])?["Region"] as? String,
           let region: AWSRegionType
           switch regionStr.lowercased() {
           case "us-west-2": region = .USWest2
           case "ap-northeast-2": region = .APNortheast2
           default:          region = .USEast1        // safe default
        }

        // Fallback to environment variables
        let accessKey = ProcessInfo.processInfo.environment["AWS_ACCESS_KEY_ID"]
        let secretKey = ProcessInfo.processInfo.environment["AWS_SECRET_ACCESS_KEY"]

        if let accessKey = accessKey, !accessKey.isEmpty, let secretKey = secretKey, !secretKey.isEmpty {
            return AWSStaticCredentialsProvider(accessKey: accessKey, secretKey: secretKey)
        }

        return nil
    }
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

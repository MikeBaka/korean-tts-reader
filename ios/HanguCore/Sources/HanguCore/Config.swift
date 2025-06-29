import Foundation
import AWSCore

enum Config {
    static func pollyRegion() -> AWSRegionType {
        return .USEast1
    }

    /// Returns an AWS credentials provider.
    static func credentialProvider() -> AWSCredentialsProvider? {

        // ① awsconfiguration.json (bundle)
        if
            let cfgPath = Bundle.main.path(forResource: "awsconfiguration", ofType: "json"),
            let cfgData = try? Data(contentsOf: URL(fileURLWithPath: cfgPath)),
            let cfg     = try? JSONSerialization.jsonObject(with: cfgData) as? [String: Any],
            let cred    = (cfg["credentialsProvider"] as? [String: Any])?["cognitoIdentity"] as? [String: Any],
            let def     = cred["Default"] as? [String: Any],
            let poolId  = def["PoolId"] as? String
        {
            let regionName = (def["Region"] as? String)?.lowercased() ?? ""
            let region: AWSRegionType = {
                switch regionName {
                case "us-west-2":      return .USWest2
                case "ap-northeast-2": return .APNortheast2
                default:               return .USEast1
                }
            }()
            return AWSCognitoCredentialsProvider(regionType: region, identityPoolId: poolId)
        }

        // ② environment variables (CI / CLI)
        let env = ProcessInfo.processInfo.environment
        if
            let ak = env["AWS_ACCESS_KEY_ID"],
            let sk = env["AWS_SECRET_ACCESS_KEY"],
            !ak.isEmpty, !sk.isEmpty
        {
            return AWSStaticCredentialsProvider(accessKey: ak, secretKey: sk)
        }

        return nil
    }
}

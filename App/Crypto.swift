import Foundation
import CryptoKit

enum Digest {
    static func sha256(_ data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }

    static func sha256(_ s: String) -> String {
        sha256(Data(s.utf8))
    }
}


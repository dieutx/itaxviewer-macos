import Foundation
import Security

public enum CertificateTrust: String, Codable, Equatable {
    case trusted = "Tin cậy theo kho tin cậy của macOS"
    case untrusted = "Không tin cậy theo kho tin cậy của macOS"
    case expired = "Chứng thư hết hiệu lực"
    case notYetValid = "Chứng thư chưa có hiệu lực"
    case unknown = "Không xác định"
}

public enum SignatureVerificationStatus: String, Codable, Equatable {
    case notVerified = "Chưa xác minh (Not verified)"
    case noSignature = "Không có chữ ký"
    case malformed = "Cấu trúc chữ ký không hợp lệ"
}

public struct SignatureInfo: Identifiable, Equatable {
    public let id: String
    public let signerName: String
    public let issuerName: String
    public let serialNumber: String
    public let notBefore: Date?
    public let notAfter: Date?
    public let signatureMethod: String?
    public let digestMethod: String?
    public let referenceURI: String?
    public let signingTime: String?
    public let timestamp: String?
    public let certificateTrust: CertificateTrust
    public let status: SignatureVerificationStatus
    public let detail: String
    public let signatureValueBytes: Int

    public var validityText: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "vi_VN")
        f.dateFormat = "dd/MM/yyyy HH:mm:ss"
        switch (notBefore, notAfter) {
        case let (nb?, na?): return "\(f.string(from: nb)) – \(f.string(from: na))"
        case let (nb?, nil): return "Từ \(f.string(from: nb))"
        case let (nil, na?): return "Đến \(f.string(from: na))"
        default: return "—"
        }
    }
}

/// Extracts XMLDSig metadata and certificate facts.
///
/// IMPORTANT: cryptographic verification of `SignatureValue` and `Reference`
/// digests (XML C14N + RSA/ECDSA) is intentionally **not** claimed here.
/// The status is always `.notVerified` so the UI can never present an
/// unverified document as valid.
public enum SignatureInspector {

    static let dsNamespace = "http://www.w3.org/2000/09/xmldsig#"

    public static func inspect(document: XMLNode) -> [SignatureInfo] {
        let nodes = document.descendants(named: "Signature")
            .filter { $0.namespaceURI == nil || $0.namespaceURI == dsNamespace || $0.localName == "Signature" }
        return nodes.enumerated().map { index, signature in
            inspect(signature: signature, index: index)
        }
    }

    private static func inspect(signature: XMLNode, index: Int) -> SignatureInfo {
        let certificates = signature.firstDescendant(named: "X509Certificate")
            .map { $0.trimmedValue.replacingOccurrences(of: "\n", with: "")
                .replacingOccurrences(of: "\r", with: "") } ?? ""

        let certData = Data(base64Encoded: certificates, options: [.ignoreUnknownCharacters])
        let parsed = certData.flatMap(parseCertificate)

        let signedInfo = signature.firstDescendant(named: "SignedInfo")
        let signatureMethod = signedInfo?.firstChild(named: "SignatureMethod")?.attribute("Algorithm")
        let reference = signedInfo?.firstDescendant(named: "Reference")
        let digestMethod = reference?.firstChild(named: "DigestMethod")?.attribute("Algorithm")
        let referenceURI = reference?.attribute("URI")

        let property = signature.firstDescendant(named: "SignatureProperty")
        let signingTime = property?.firstDescendant(named: "SigningTime")?.trimmedValue
            ?? signature.firstDescendant(named: "SigningTime")?.trimmedValue
        let timestamp = property?.firstDescendant(named: "DateTimeStamp")?.trimmedValue

        let signatureValue = signature.firstDescendant(named: "SignatureValue")?.trimmedValue ?? ""
        let valueBytes = Data(base64Encoded: signatureValue,
                              options: [.ignoreUnknownCharacters])?.count ?? 0

        let status: SignatureVerificationStatus = parsed == nil ? .malformed : .notVerified
        let detail: String
        if parsed == nil {
            detail = "Có phần tử ds:Signature nhưng không đọc được chứng thư X509 trong KeyInfo."
        } else {
            detail = "Đã đọc cấu trúc chữ ký và chứng thư. Chưa thực hiện kiểm tra mật mã XMLDSig (C14N + digest + SignatureValue)."
        }

        return SignatureInfo(
            id: "sig-\(index)-\(referenceURI ?? "")",
            signerName: parsed?.subject ?? "[Không đọc được chủ thể chứng thư]",
            issuerName: parsed?.issuer ?? "—",
            serialNumber: parsed?.serial ?? "—",
            notBefore: parsed?.notBefore,
            notAfter: parsed?.notAfter,
            signatureMethod: signatureMethod,
            digestMethod: digestMethod,
            referenceURI: referenceURI,
            signingTime: signingTime,
            timestamp: timestamp,
            certificateTrust: parsed?.trust ?? .unknown,
            status: status,
            detail: detail,
            signatureValueBytes: valueBytes
        )
    }

    private struct ParsedCertificate {
        let subject: String
        let issuer: String
        let serial: String
        let notBefore: Date?
        let notAfter: Date?
        let trust: CertificateTrust
    }

    private static func parseCertificate(_ data: Data) -> ParsedCertificate? {
        guard let certificate = SecCertificateCreateWithData(nil, data as CFData) else { return nil }

        let subject = (SecCertificateCopySubjectSummary(certificate) as String?) ?? "—"
        var values: NSDictionary?
        if let raw = SecCertificateCopyValues(
            certificate,
            [kSecOIDX509V1IssuerName,
             kSecOIDX509V1SerialNumber,
             kSecOIDX509V1ValidityNotBefore,
             kSecOIDX509V1ValidityNotAfter] as CFArray,
            nil
        ) {
            values = raw as NSDictionary
        }

        let issuer = dictionaryValue(values, kSecOIDX509V1IssuerName).flatMap { entry -> String? in
            // The issuer name is an array of {label, value} entries.
            if let list = entry as? [[String: Any]] {
                return list.compactMap { $0[kSecPropertyKeyValue as String] as? String }
                    .joined(separator: ", ")
            }
            return entry as? String
        } ?? "—"

        let serial = dictionaryValue(values, kSecOIDX509V1SerialNumber) as? String ?? "—"
        let notBefore = dictionaryValue(values, kSecOIDX509V1ValidityNotBefore) as? Date
        let notAfter = dictionaryValue(values, kSecOIDX509V1ValidityNotAfter) as? Date

        var trust: CertificateTrust = .unknown
        let policy = SecPolicyCreateBasicX509()
        var trustRef: SecTrust?
        if SecTrustCreateWithCertificates(certificate, policy, &trustRef) == errSecSuccess,
           let trustRef {
            // Certificate inspection must remain offline (no AIA/OCSP fetches).
            SecTrustSetNetworkFetchAllowed(trustRef, false)
            var error: CFError?
            let ok = SecTrustEvaluateWithError(trustRef, &error)
            if ok {
                trust = .trusted
            } else if let notAfter, notAfter < Date() {
                trust = .expired
            } else if let notBefore, notBefore > Date() {
                trust = .notYetValid
            } else {
                trust = .untrusted
            }
        }

        return ParsedCertificate(subject: subject,
                                 issuer: issuer,
                                 serial: serial,
                                 notBefore: notBefore,
                                 notAfter: notAfter,
                                 trust: trust)
    }

    private static func dictionaryValue(_ dictionary: NSDictionary?, _ key: CFString) -> Any? {
        guard let entry = dictionary?[key] as? NSDictionary else { return nil }
        return entry[kSecPropertyKeyValue]
    }
}


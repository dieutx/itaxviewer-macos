# Digital Signature Handling — Recovered Behaviour and macOS Policy

## 1. Classes involved

| Class | Role |
|---|---|
| `IHTKKXMLSignature` (27 KB) | XMLDSig verification for declarations, notices, vouchers |
| `IHTKKXMLTemSignature` (18 KB) | Verification variant for “tem điện tử” (stamp) documents |
| `CertVerifier` (15.6 KB) | PKIX path validation, certificate lookup, OCSP revocation |
| `XMLSignatureValidationResult` | Result model: signer CN, position, signing time, status, message |
| `X509KeySelector` | Resolves the verification key from `KeyInfo/X509Data` |
| `X500PrincipalHelper` | Extracts CN from the certificate subject |
| `SignatureList` | SWT dialog shown by “Xác minh chữ ký điện tử” |

## 2. Verification sequence (declarations)

`IHTKKXMLSignature.verifyXMLSignature(Document doc)` lines 96–222:

1. `XMLSignatureFactory.getInstance("DOM")` (JDK built-in XMLDSig; BouncyCastle is the
   provider for certificate path/OCSP).
2. Locate the signed node: XPath `/HSoThueDTu/HSoKhaiThue`. If absent, fall back to
   `checkSignXpath = true` and still process every `ds:Signature`.
3. Read the node's `Id`/`id` attribute → `referenceURI`.
4. Register **every** element's `Id` attribute via `Element.setIdAttribute("Id", true)` so
   same-document references resolve.
5. For each `ds:Signature`:
   * read `SignatureProperty` → `DateTimeStamp`, else `SigningTime`;
   * normalise the value to `ddMMyyyyHHmmss` (two format helpers, one HDDT-specific);
   * `DOMValidateContext(new X509KeySelector(), signatureNode)`;
   * `fac.unmarshalXMLSignature(...)`;
   * extract the certificate chain from `KeyInfo/X509Data`;
   * `signature.validate(context)`;
   * `certVerifier.verifyCertificationChain(null, leaf, chain)`;
   * `certVerifier.checkRevocationStatus(leaf, trustedCerts)`.
6. Result status:
   * `ITaxSigValidException` → **ERROR** (signature invalid)
   * `ITaxCertValidException` → **ERROR** (certificate invalid)
   * `ITaxStatusValidException` → **WARNING** (revocation status unavailable)
   * `IllegalArgumentException` → **ERROR**
7. `verifyXMLSignature(XMLSignature, DOMValidateContext)` (lines 461–484) checks:
   * `signature.validate(context)`;
   * `signature.getSignatureValue().validate(context)`;
   * every `Reference.validate(context)`.

HDDT documents (`maTKhai` 1140/1164/1165) use `verifyXMLSignatureHHDT`; e-invoice notices
use `verifyXMLSignatureTBaoHDDT`; “tem” documents use `IHTKKXMLTemSignature`. All follow the
same DOMValidateContext pattern with different signed-node XPaths.

## 3. Certificate trust

`CertVerifier` (`signature/CertVerifier.java`):

| Step | Implementation |
|---|---|
| Anchors | `ConfigInfo` loads **all** files in `certstore/root` (76 certs) as `TrustAnchor`s |
| Intermediates | `certstore/trust` (124 certs) used to find OCSP issuer certificates |
| Path validation | `CertPathValidator` type `PKIX` with BouncyCastle provider |
| Revocation in path | **disabled** (`setRevocationEnabled(false)`) |
| Revocation check | separate **OCSP** request to the certificate's AIA OCSP URL |
| OCSP transport | `URLConnection`, 20 s connect/read timeout; no CRL fallback |
| No OCSP URL | warning: “Không tìm thấy chứng thư số của nhà cung cấp dịch vụ chứng thư số …” |
| Network failure | warning: “Không thể kết nối Internet tới đơn vị CA để kiểm tra tình trạng thu hồi …” |
| Special case | `http://ocsp.ca.ptc` rewritten to `http://ocsp.ca.gov.vn` |
| Serial check | OCSP request carries the certificate serial; `RevokedStatus` → revoked; `UnknownStatus` → unknown |

The original therefore performs **online revocation checking**. On an offline machine it
degrades to a warning, not a hard failure.

## 4. Timestamp

The application reads `DateTimeStamp` / `SigningTime` from `SignatureProperty` and displays
it. There is **no RFC 3161 timestamp-token validation** and no signature over the timestamp
in the code path inspected. It is a claimed signing time, not a verified trusted timestamp.

## 5. Result model and UI

`XMLSignatureValidationResult`:

```java
SIG_STATUS_GOOD    = 0  → green  icon, "Chữ ký điện tử hợp lệ"
SIG_STATUS_WARNING = 1  → yellow icon, message (e.g. OCSP unreachable)
SIG_STATUS_ERROR   = 2  → red    icon, message
```

`getSignerName()` returns the certificate **CN**, or
`[Không biết chủ thể của chứng thư số]` if the chain is missing. `getChucVu()` holds a
position/title when present. `HSoThueViewer.getSigStatusHTML` renders a status table inside
the document and the “Chữ ký điện tử” menu opens the full `SignatureList` dialog.

## 6. What the macOS application implements

`SignatureInspector.swift`:

| Capability | Implemented? | Detail |
|---|---|---|
| Detect `ds:Signature` (any namespace variant) | ✅ | local-name based |
| Count signatures | ✅ | one card per signature |
| Parse `SignedInfo` algorithms | ✅ | `SignatureMethod`, `DigestMethod`, `Reference@URI` |
| Parse `KeyInfo/X509Data/X509Certificate` | ✅ | Base64 → DER → `SecCertificateCreateWithData` |
| Signer CN | ✅ | `SecCertificateCopySubjectSummary` |
| Issuer, serial, validity dates | ✅ | `SecCertificateCopyValues` (X509v1 OIDs) |
| Certificate chain trust | ✅ (system only) | `SecTrustCreateWithCertificates` + `SecTrustEvaluateWithError` |
| Revocation (OCSP/CRL) | ❌ | explicitly “not checked (offline)” |
| XML C14N canonicalisation | ❌ | not implemented |
| `Reference` digest verification | ❌ | not implemented |
| `SignatureValue` RSA/ECDSA verification | ❌ | not implemented |
| Trusted timestamp verification | ❌ | signing time shown as claimed |
| Claim “document is valid” | ❌ | never |

### Status policy

Every signature is reported as:

```
Chưa xác minh (Not verified)
```

The UI banner states that cryptographic verification and revocation checking are not
performed. Certificate trust is shown separately (“Tin cậy theo kho tin cậy của macOS” /
“Không tin cậy…”) with an explicit warning that Vietnamese CA certificates are often absent
from the macOS system trust store, so “untrusted” does **not** mean “forged”.

This satisfies the requirement: if complete verification is not implemented, display
“Not verified” rather than claiming validity.

## 7. Path to full verification (documented, not claimed)

1. Implement XML C14N 1.0/1.1 (inclusive + exclusive) over the referenced subtree,
   including namespace propagation and attribute ordering.
2. Compute the declared digest (`sha1`, `sha256`, `sha512`) and compare in constant time.
3. Verify `SignedInfo` with `SecKeyVerifySignature` using the leaf certificate's public key.
4. Build and evaluate a chain with the certificate bundle at
   `Certificates/` (optional) plus `SecTrustSetNetworkFetchAllowed(false)`.
5. Add an explicit “revocation: not checked (offline)” field; optionally allow the user to
   opt into an online OCSP check with consent.
6. Only then introduce a green “valid” state and never reuse the original’s wording
   without the same checks.

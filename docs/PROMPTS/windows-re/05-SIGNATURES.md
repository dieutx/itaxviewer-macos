# 05 — Chữ ký số (XMLDSig) & hiển thị/in

Mục tiêu: clone **cách iTax Viewer hiển thị, kiểm tra và in chữ ký số** đạt 90–100%. Đây là
phần app macOS hiện mới chỉ đọc metadata và **luôn** trả trạng thái “chưa xác minh”.

## 1. Hiện trạng macOS

- `SignatureInspector` đọc `SignatureValue`, `X509Certificate`, `X509SubjectName`,
  `DigestValue`, `SigningTime` (nếu có) và hiển thị danh sách chữ ký.
- Không có C14N/digest/verify thật; không kết luận chữ ký hợp lệ.
- Không có ảnh/seal; không copy assets của hãng.

## 2. Cần reverse trên Windows

### 2.1 Giao diện & trạng thái

1. Khi mở file có chữ ký, app hiển thị gì? (icon, panel, tooltip, dòng trạng thái)
2. Các trạng thái có thể có, nguyên văn tiếng Việt:
   - hợp lệ
   - không hợp lệ / bị sửa
   - không tin cậy / không tìm thấy chuỗi chứng thư
   - chứng thư hết hạn / chưa hiệu lực
   - thiếu chứng thư / không có chữ ký
   - chữ ký số của cơ quan thuế vs người nộp thuế
3. Có hiển thị tên người ký, MST, đơn vị, thời gian ký, thời gian TSA không?
4. Có cho xem chi tiết chứng thư (subject/issuer/serial/validity/key usage) không?
5. Có kiểm tra chữ ký mật mã thật hay chỉ hiển thị metadata? Thử sửa 1 byte XML xem app
   báo gì — đây là bằng chứng quan trọng.

### 2.2 Thuật toán & cấu trúc

Ghi rõ từ XML mẫu và từ hành vi app:

- Canonicalization: `C14N`, `C14N11`, `exc-c14n` (+ InclusiveNamespaces?).
- Transforms: enveloped-signature, các transform khác.
- Digest: SHA-1 / SHA-256 / SHA-512.
- Signature: RSA PKCS#1 v1.5, RSA-PSS, ECDSA (P-256/P-384)?
- `KeyInfo` dạng gì: X509Data, RSAKeyValue, SubjectName?
- Có `SignedInfo` với nhiều `Reference` không; Reference nào là toàn file, Reference nào
  là `_NODE_TO_SIGN`?
- Có timestamp TSA (`SignatureTimeStamp`, `xades:UnsignedSignatureProperties`) không?
- Chữ ký có bị bọc ngoài (`TBaoThueDTu/CKyDTu/Signature`) hay nằm trong node con?
- Nhiều chữ ký: thứ tự hiển thị, chữ ký của NNT và của CQT.

### 2.3 Trust / chứng thư

- App có kiểm tra chuỗi tin cậy không; dùng trust store nào (Windows Certificate Store,
  Java cacerts, file riêng)?
- Có kiểm tra CRL/OCSP không; có yêu cầu mạng không?
- Có kiểm tra `keyUsage = nonRepudiation/digitalSignature` không?
- Có kiểm tra MST trong chứng thư khớp MST hồ sơ không?
- Chứng thư hết hạn tại thời điểm ký vs hiện tại — app báo gì?

### 2.4 In / PDF

- Khối chữ ký in ở cuối trang hay trang riêng?
- In tên người ký, chức danh, đơn vị, thời gian, “Ký số” / hình ảnh seal?
- Có in mã hash / serial không?
- Có khác nhau giữa tờ khai, thông báo, chứng từ?

## 3. Bộ test vector phải tạo (trên Windows)

Dùng **chứng thư test tự tạo**, không dùng cert thật của ai:

| # | Case | Kỳ vọng app gốc |
|---|---|---|
| S1 | Chữ ký hợp lệ, cert còn hạn, chain đầy đủ | hợp lệ |
| S2 | Sửa 1 byte trong nội dung sau khi ký | không hợp lệ |
| S3 | Sửa `SignatureValue` | không hợp lệ |
| S4 | Cert hết hạn | trạng thái tương ứng |
| S5 | Cert tự ký không có trong trust store | không tin cậy |
| S6 | Thiếu `X509Certificate` | thiếu chứng thư |
| S7 | Hai chữ ký (NNT + CQT) | hiển thị cả hai |
| S8 | Có timestamp TSA | hiển thị thời gian TSA |
| S9 | File không có chữ ký | không có chữ ký |
| S10 | Chữ ký trên node `_NODE_TO_SIGN` | hợp lệ |

Với mỗi case: ảnh panel chữ ký, ảnh chi tiết cert, ảnh thông báo lỗi, file XML (đã thay
cert test), và ghi rõ app version.

## 4. Output contract

### 4.1 Spec

`docs/reverse-engineering/signatures/signature-spec.json`:

```json
{
  "appVersion": "…",
  "windowsVersion": "…",
  "captureDate": "2026-…",
  "algorithms": {
    "canonicalization": ["exc-c14n", "c14n"],
    "digest": ["sha256", "sha1"],
    "signature": ["rsa-sha256", "rsa-sha1"]
  },
  "ui": {
    "panelTitle": "…",
    "statusStrings": {
      "valid": "…",
      "invalid": "…",
      "untrusted": "…",
      "expired": "…",
      "missingCert": "…",
      "noSignature": "…"
    },
    "fields": ["signerName", "taxCode", "issuer", "serial", "signingTime", "tsaTime"]
  },
  "verification": {
    "checksDigest": true,
    "checksSignature": true,
    "checksChain": true,
    "checksRevocation": false,
    "checksKeyUsage": true,
    "checksTaxCode": false
  },
  "printing": {
    "signatureBlock": "text|image|none",
    "separatePage": false
  },
  "unknowns": []
}
```

### 4.2 Fixture & evidence

- `test-data/signatures/` (hoặc `docs/reverse-engineering/signatures/fixtures/`) chứa XML
  test với cert test; **không** chứa cert/MST thật.
- `evidence/signatures/<case>/` chứa ảnh/PDF.
- `results/signatures.md` mô tả từng case.

## 5. Yêu cầu cho phía macOS (để implement đúng)

1. Verify theo đúng transform + C14N; hỗ trợ ít nhất SHA-256/RSA.
2. Tách **signature validity** (mật mã) khỏi **trust** (chain/OS trust store).
3. Hiển thị đúng chuỗi trạng thái như bản gốc; không tự nâng thành “hợp lệ”.
4. Không gọi mạng để OCSP/CRL trừ khi có yêu cầu rõ; mặc định offline.
5. Không copy seal/ảnh của hãng; chỉ in text theo đúng bố cục.
6. Nếu app gốc chỉ đọc metadata (không verify), clone đúng hành vi đó + ghi rõ.

## 6. Handoff

```text
BATCH: SIGNATURE-<...>
APP: iTax Viewer <version> · Windows <...>
CASES: S1..S10 — <case nào chạy được>
PHÁT HIỆN: <verify thật hay metadata; thuật toán; chuỗi trạng thái; trust store>
ĐÃ TẠO: signatures/signature-spec.json, fixtures, evidence, results/signatures.md
UNKNOWNS: ...
```

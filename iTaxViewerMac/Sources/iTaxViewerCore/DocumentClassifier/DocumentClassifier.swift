import Foundation

public enum DocumentError: Error, LocalizedError, Equatable {
    case unsupportedRoot(String)
    case invalidStructure(String)
    case missingField(String)
    case unknownForm(code: String, version: String?)
    case registryMissing(String)

    public var errorDescription: String? {
        switch self {
        case .unsupportedRoot(let root):
            return "Loại hồ sơ chưa được hỗ trợ (phần tử gốc: \(root))."
        case .invalidStructure(let detail):
            return "Cấu trúc tệp hồ sơ không đúng: \(detail)"
        case .missingField(let field):
            return "Cấu trúc tệp hồ sơ không đúng: không có thẻ dữ liệu '\(field)'"
        case .unknownForm(let code, let version):
            return "Mã hồ sơ (\(code)) hoặc phiên bản hồ sơ (\(version ?? "?")) không đúng"
        case .registryMissing(let name):
            return "Thiếu dữ liệu danh mục biểu mẫu: \(name)"
        }
    }
}

public enum DocumentKind: String, Codable, Equatable {
    case declaration = "Tờ khai thuế"
    case notice = "Thông báo / văn bản của cơ quan thuế"
    case paymentVoucher = "Giấy nộp tiền / chứng từ"
    case registration = "Đăng ký thuế"
    case catalog = "Danh mục"
    case customs = "Hồ sơ hải quan"
    case invoice = "Tài liệu hóa đơn điện tử"
    case unsupported = "Không xác định"
}

public enum RenderSupport {
    case full(FormSpec)
    case generic
    case none

    public var isFull: Bool {
        if case .full = self { return true }
        return false
    }

    public var label: String {
        switch self {
        case .full: return "Rendering đầy đủ"
        case .generic: return "Hiển thị dữ liệu có cấu trúc (layout đang hoàn thiện)"
        case .none: return "Không hỗ trợ"
        }
    }
}

public struct Classification {
    public let kind: DocumentKind
    public let displayCode: String?
    public let registryCode: String?
    public let formVersion: String?
    public let orientation: PageOrientation
    public let support: RenderSupport
    public let warnings: [String]

    public var displayName: String {
        if let displayCode { return "\(displayCode) — \(kind.rawValue)" }
        return kind.rawValue
    }
}

public enum PageOrientation: String, Codable, Equatable {
    case portrait
    case landscape
}

public enum DocumentClassifier {

    private static let declarationRoot = "HSoThueDTu"
    private static let noticeRoots: Set<String> = [
        "TBaoThueDTu", "THONGBAO", "THONG_BAO", "TBAO_TKHOAN_NH",
        "TBAO_TKHOAN_NT", "TBAO_NGUNG", "BKE_TBAO"
    ]
    private static let invoiceRoots: Set<String> = ["TKhai", "DNghi", "TBao", "BCTHSDBLai", "BLai"]
    private static let registrationRoots: Set<String> = ["DKyThueDTu"]
    private static let catalogRoots: Set<String> = ["DanhMucDTu"]
    private static let customsRoots: Set<String> = ["TOKHAI_OBJ", "TOKHAISUA_OBJ"]

    /// Form codes for which the original application ignores `loaiTKhai`
    /// and looks up a declaration-specific (DKT) template.
    private static let declarationTemplateCodes: Set<String> = [
        "680", "800", "801", "802", "803", "804", "805", "806", "807", "808", "809",
        "810", "811", "814", "815", "816", "823", "826", "827", "900", "901", "902",
        "903", "904", "905", "906", "907", "909", "910", "911", "913", "845", "912",
        "962", "1120", "954", "955", "1130", "1131", "1132", "1133", "1134", "1135",
        "1136", "1137", "1158", "1175", "1176", "1165", "1229", "1124", "1301",
        "1303", "2110", "1304", "2108", "1310", "1311", "1305", "2116", "2117",
        "1312", "1313", "1314"
    ]

    public static func classify(_ document: TaxDocument,
                                registry: FormRegistry) throws -> Classification {
        let meta = document.metadata
        let root = document.root.localName

        switch root {
        case declarationRoot:
            return try classifyDeclaration(document, registry: registry)
        case "CHUNGTU":
            return Classification(kind: .paymentVoucher,
                                  displayCode: meta.voucherCode.map { "CT-\($0)" },
                                  registryCode: meta.voucherCode,
                                  formVersion: meta.formVersion,
                                  orientation: .portrait,
                                  support: .generic,
                                  warnings: ["Chứng từ được hiển thị dạng bảng dữ liệu; mẫu in chính thức của từng loại chứng từ chưa được tái tạo đầy đủ."])
        case _ where noticeRoots.contains(root):
            return Classification(kind: .notice,
                                  displayCode: meta.noticeCode.flatMap { registry.codeInfo($0)?.displayCode }
                                      ?? meta.formDescription
                                      ?? meta.noticeCode.map { "TB-\($0)" },
                                  registryCode: meta.noticeCode,
                                  formVersion: meta.noticeVersion,
                                  orientation: .portrait,
                                  support: .generic,
                                  warnings: ["Văn bản/thông báo được hiển thị dạng dữ liệu có cấu trúc. Nội dung diễn giải theo từng mẫu thông báo chưa được tái tạo đầy đủ."])
        case _ where registrationRoots.contains(root):
            return Classification(kind: .registration,
                                  displayCode: meta.formCode,
                                  registryCode: meta.formCode,
                                  formVersion: meta.formVersion,
                                  orientation: .portrait,
                                  support: .generic,
                                  warnings: ["Hồ sơ đăng ký thuế được hiển thị dạng bảng dữ liệu."])
        case _ where catalogRoots.contains(root):
            return Classification(kind: .catalog,
                                  displayCode: nil,
                                  registryCode: nil,
                                  formVersion: nil,
                                  orientation: .portrait,
                                  support: .generic,
                                  warnings: ["Tệp danh mục nghiệp vụ, không phải tờ khai."])
        case _ where invoiceRoots.contains(root):
            let mso = document.root.firstDescendant(named: "MSo")?.trimmedValue
            return Classification(kind: .invoice,
                                  displayCode: mso,
                                  registryCode: meta.noticeCode,
                                  formVersion: meta.formVersion,
                                  orientation: .portrait,
                                  support: .generic,
                                  warnings: ["Tài liệu hóa đơn điện tử được hiển thị dạng dữ liệu có cấu trúc."])
        case _ where customsRoots.contains(root) || root.hasSuffix(":Envelope"):
            return Classification(kind: .customs,
                                  displayCode: meta.customsCode,
                                  registryCode: nil,
                                  formVersion: nil,
                                  orientation: .portrait,
                                  support: .generic,
                                  warnings: ["Hồ sơ hải quan được hiển thị dạng bảng dữ liệu."])
        default:
            throw DocumentError.unsupportedRoot(root)
        }
    }

    private static func classifyDeclaration(_ document: TaxDocument,
                                            registry: FormRegistry) throws -> Classification {
        guard let khai = document.root.firstDescendant(named: "TKhaiThue") else {
            throw DocumentError.invalidStructure("không có thẻ 'TKhaiThue'")
        }
        guard let code = khai.firstChild(named: "maTKhai")?.trimmedValue, !code.isEmpty else {
            throw DocumentError.missingField("maTKhai")
        }
        guard let version = khai.firstChild(named: "pbanTKhaiXML")?.trimmedValue, !version.isEmpty else {
            throw DocumentError.missingField("pbanTKhaiXML")
        }
        let filingType = khai.firstChild(named: "loaiTKhai")?.trimmedValue
        if filingType == nil && !declarationTemplateCodes.contains(code) {
            throw DocumentError.missingField("loaiTKhai")
        }
        guard let title = khai.firstChild(named: "tenTKhai")?.trimmedValue, !title.isEmpty else {
            throw DocumentError.missingField("tenTKhai")
        }

        var warnings: [String] = []
        let effectiveVersion = registry.normalizedVersion(code: code, version: version)
        let codeInfo = registry.codeInfo(code)
        let displayCode = codeInfo?.displayCode
        var orientation: PageOrientation = (codeInfo?.orientation == "1") ? .landscape : .portrait

        if let form = registry.resolve(code: code, version: version, filingType: filingType) {
            orientation = form.isLandscape ? .landscape : .portrait
            if let spec = registry.spec(for: form.displayCode) {
                if !form.versions.contains(effectiveVersion ?? "") {
                    warnings.append("Phiên bản hồ sơ \(version) chưa có trong danh sách đã kiểm chứng (\(form.versions.joined(separator: ", "))). Biểu mẫu được hiển thị theo phiên bản gần nhất; cần đối chiếu với iTaxViewer gốc.")
                }
                return Classification(kind: .declaration,
                                      displayCode: form.displayCode,
                                      registryCode: code,
                                      formVersion: version,
                                      orientation: orientation,
                                      support: .full(spec),
                                      warnings: warnings)
            }
        }

        if codeInfo == nil {
            warnings.append("Mã hồ sơ \(code) không có trong danh mục biểu mẫu đi kèm.")
        } else if displayCode == nil {
            warnings.append("Không xác định được mã hiển thị (Mẫu số) cho mã hồ sơ \(code).")
        } else {
            warnings.append("Biểu mẫu \(displayCode ?? code) chưa có renderer đầy đủ; đang hiển thị toàn bộ trường dữ liệu.")
        }
        return Classification(kind: .declaration,
                              displayCode: displayCode,
                              registryCode: code,
                              formVersion: version,
                              orientation: orientation,
                              support: .generic,
                              warnings: warnings)
    }
}


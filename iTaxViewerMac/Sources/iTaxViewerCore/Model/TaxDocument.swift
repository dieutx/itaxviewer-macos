import Foundation

public struct DocumentMetadata: Equatable {
    public var title: String?
    public var formCode: String?
    public var formVersion: String?
    public var filingType: String?
    public var supplementNumber: String?
    public var periodType: String?
    public var period: String?
    public var periodFrom: String?
    public var periodTo: String?
    public var filingDate: String?
    public var taxpayerName: String?
    public var taxpayerTaxCode: String?
    public var taxpayerAddress: String?
    public var taxpayerWard: String?
    public var taxpayerDistrict: String?
    public var taxpayerProvince: String?
    public var taxpayerPhone: String?
    public var taxpayerFax: String?
    public var taxpayerEmail: String?
    public var activityName: String?
    public var activityRate: String?
    public var dependentUnitName: String?
    public var dependentUnitTaxCode: String?
    public var dependentWard: String?
    public var dependentDistrict: String?
    public var dependentProvince: String?
    public var agentName: String?
    public var agentTaxCode: String?
    public var agentAddress: String?
    public var agentDistrict: String?
    public var agentProvince: String?
    public var agentPhone: String?
    public var agentFax: String?
    public var agentEmail: String?
    public var agentContractNumber: String?
    public var agentContractDate: String?
    public var softwareName: String?
    public var softwareVersion: String?
    public var formDescription: String?
    public var noticeCode: String?
    public var noticeVersion: String?
    public var voucherCode: String?
    public var voucherNumber: String?
    public var customsCode: String?
    public var registrationCode: String?

    public init() {}
}

public struct TaxDocument {
    public let root: XMLNode
    public let metadata: DocumentMetadata
    public let sourceURL: URL?
    public let sourceName: String
    public let byteCount: Int
    public let signatures: [SignatureInfo]
    public let warnings: [String]

    public init(root: XMLNode,
                metadata: DocumentMetadata,
                sourceURL: URL?,
                sourceName: String,
                byteCount: Int,
                signatures: [SignatureInfo],
                warnings: [String]) {
        self.root = root
        self.metadata = metadata
        self.sourceURL = sourceURL
        self.sourceName = sourceName
        self.byteCount = byteCount
        self.signatures = signatures
        self.warnings = warnings
    }

    public static func load(url: URL, limits: XMLSecurityLimits = .init()) throws -> TaxDocument {
        guard url.isFileURL, url.host == nil || url.host == "" || url.host == "localhost" else {
            throw DocumentError.invalidStructure("Chỉ mở tệp XML trên máy; không tải hồ sơ qua mạng.")
        }
        let data = try Data(contentsOf: url, options: [.mappedIfSafe])
        let root = try SecureXMLParser.parse(data: data, limits: limits)
        let metadata = MetadataExtractor.extract(from: root)
        let signatures = SignatureInspector.inspect(document: root)
        var warnings: [String] = []
        if root.firstDescendant(named: "Signature") != nil {
            warnings.append("Tệp có chữ ký số. Ứng dụng hiển thị thông tin chứng thư nhưng chưa xác minh mật mã chữ ký.")
        }
        return TaxDocument(root: root,
                           metadata: metadata,
                           sourceURL: url,
                           sourceName: url.lastPathComponent,
                           byteCount: data.count,
                           signatures: signatures,
                           warnings: warnings)
    }

    public static func load(data: Data, sourceName: String) throws -> TaxDocument {
        let root = try SecureXMLParser.parse(data: data)
        let metadata = MetadataExtractor.extract(from: root)
        return TaxDocument(root: root,
                           metadata: metadata,
                           sourceURL: nil,
                           sourceName: sourceName,
                           byteCount: data.count,
                           signatures: SignatureInspector.inspect(document: root),
                           warnings: [])
    }
}

enum MetadataExtractor {

    static func extract(from root: XMLNode) -> DocumentMetadata {
        var meta = DocumentMetadata()

        if let khai = root.firstDescendant(named: "TKhaiThue") {
            meta.formCode = value(khai, "maTKhai")
            meta.title = value(khai, "tenTKhai")
            meta.formVersion = value(khai, "pbanTKhaiXML")
            meta.filingType = value(khai, "loaiTKhai")
            meta.supplementNumber = value(khai, "soLan")
            meta.filingDate = value(khai, "ngayLapTKhai")
            meta.formDescription = value(khai, "moTaBMau") ?? value(khai, "moTaBieuMau")
            if let period = khai.firstChild(named: "KyKKhaiThue") {
                meta.periodType = value(period, "kieuKy")
                meta.period = value(period, "kyKKhai")
                meta.periodFrom = value(period, "kyKKhaiTuNgay")
                meta.periodTo = value(period, "kyKKhaiDenNgay")
            }
        }

        if let nnt = root.firstDescendant(named: "NNT") {
            meta.taxpayerName = value(nnt, "tenNNT")
            meta.taxpayerTaxCode = value(nnt, "mst")
            meta.taxpayerAddress = value(nnt, "dchiNNT")
            meta.taxpayerWard = value(nnt, "tenXaNNT")
            meta.taxpayerDistrict = value(nnt, "tenHuyenNNT")
            meta.taxpayerProvince = value(nnt, "tenTinhNNT")
            meta.taxpayerPhone = value(nnt, "dthoaiNNT")
            meta.taxpayerFax = value(nnt, "faxNNT")
            meta.taxpayerEmail = value(nnt, "emailNNT")
        }

        if let agent = root.firstDescendant(named: "DLyThue") {
            meta.agentName = value(agent, "tenDLyThue")
            meta.agentTaxCode = value(agent, "mstDLyThue")
            meta.agentAddress = value(agent, "dchiDLyThue")
            meta.agentDistrict = value(agent, "tenHuyenDLyThue")
            meta.agentProvince = value(agent, "tenTinhDLyThue")
            meta.agentPhone = value(agent, "dthoaiDLyThue")
            meta.agentFax = value(agent, "faxDLyThue")
            meta.agentEmail = value(agent, "emailDLyThue")
            meta.agentContractNumber = value(agent, "soHDongDLyThue")
            meta.agentContractDate = value(agent, "ngayKyHDDLyThue")
        }

        if let tkchinh = root.firstDescendant(named: "CTieuTKhaiChinh") {
            meta.activityName = value(tkchinh, "ten_NganhNghe")
                ?? value(tkchinh.node(atLocalPath: "Header") ?? tkchinh, "ct04_ten")
            meta.activityRate = value(tkchinh.node(atLocalPath: "Header") ?? tkchinh, "ct05")
            meta.dependentUnitName = value(tkchinh.node(atLocalPath: "Header") ?? tkchinh, "ct09")
            meta.dependentUnitTaxCode = value(tkchinh.node(atLocalPath: "Header") ?? tkchinh, "ct10")
            if let address = tkchinh.node(atLocalPath: "Header/DiaChiHDSXKDKhacTinhNDTSC") {
                meta.dependentWard = value(address, "ct11a_phuongXa_ten")
                meta.dependentDistrict = value(address, "ct11b_quanHuyen_ten")
                meta.dependentProvince = value(address, "ct11c_tinhTP_ten")
            }
        }

        if let dv = root.firstDescendant(named: "TTinDVu") {
            meta.softwareName = value(dv, "tenDVu") ?? value(dv, "maDVu")
            meta.softwareVersion = value(dv, "pbanDVu")
        }

        if let tbao = root.firstDescendant(named: "TBao") {
            meta.noticeCode = value(tbao, "maTBao") ?? value(root, "maTBao")
                ?? descendantValue(tbao, "MSo")
            meta.noticeVersion = value(tbao, "pbanTBao") ?? value(root, "pbanTBao")
                ?? descendantValue(tbao, "PBan")
            meta.title = meta.title ?? value(tbao, "tenTBao")
            meta.taxpayerName = meta.taxpayerName ?? value(tbao, "tenNNT")
            meta.taxpayerTaxCode = meta.taxpayerTaxCode ?? value(tbao, "mst")
            meta.formDescription = meta.formDescription ?? value(tbao, "MSo")
        } else if let info = root.firstDescendant(named: "TTinTBaoThue") {
            // TBaoThueDTu family: maTBao/pbanTBao/tenTBao live in TTinTBaoThue.
            meta.noticeCode = value(info, "maTBao") ?? value(root, "maTBao")
            meta.noticeVersion = value(info, "pbanTBao") ?? value(root, "pbanTBao")
            meta.title = meta.title ?? value(info, "tenTBao")
        }

        if root.localName == "CHUNGTU" {
            meta.voucherCode = descendantValue(root, "MA_CTU") ?? descendantValue(root, "MAHIEU_CTU")
            meta.voucherNumber = descendantValue(root, "SO_GNT") ?? descendantValue(root, "SO_CTU")
            meta.formVersion = descendantValue(root, "PBAN_TLIEU_XML")
            meta.taxpayerTaxCode = descendantValue(root, "MST_NNOP")
            meta.taxpayerName = descendantValue(root, "TEN_NNOP")
            meta.title = meta.title ?? "Giấy nộp tiền vào ngân sách nhà nước"
        }

        if root.localName == "TBTNhan" {
            meta.noticeCode = descendantValue(root, "MSo")
            meta.noticeVersion = descendantValue(root, "PBan")
        }

        if ["THONGBAO", "THONG_BAO", "TBAO_TKHOAN_NH", "TBAO_TKHOAN_NT", "TBAO_NGUNG"].contains(root.localName) {
            meta.noticeCode = descendantValue(root, "MA_THONGBAO") ?? descendantValue(root, "MA_TBAO")
            meta.noticeVersion = descendantValue(root, "PBAN_TLIEU_XML") ?? "4.0.0"
        }

        if root.localName == "DKyThueDTu" {
            // DKyThue.java reads these descendants, not root-level pbanHSo.
            meta.formCode = descendantValue(root, "maDKy") ?? value(root, "maHSo")
            meta.formVersion = descendantValue(root, "pBanDKy") ?? value(root, "pbanHSo")
            meta.registrationCode = meta.formCode
        }

        if root.localName == "TOKHAI_OBJ" || root.localName == "TOKHAISUA_OBJ" || root.localName == "Envelope" {
            meta.customsCode = descendantValue(root, "MA_HIEU_CTU")
                ?? descendantValue(root, "MAHIEU_CTU") ?? descendantValue(root, "ExImCode")
        }

        return meta
    }

    static func value(_ node: XMLNode, _ localName: String) -> String? {
        guard let child = node.firstChild(named: localName) else { return nil }
        let v = child.trimmedValue
        return v.isEmpty ? nil : v
    }

    static func descendantValue(_ node: XMLNode, _ localName: String) -> String? {
        guard let child = node.firstDescendant(named: localName) else { return nil }
        let v = child.trimmedValue
        return v.isEmpty ? nil : v
    }
}

import Foundation

public enum VietnameseFormat {

    /// Faithful port of the `ihtkk:formatNumber` JavaScript used by the shipped
    /// templates (msxsl:script in common.xsl):
    ///  * rounds to an integer using Math.floor(x*100 + 0.5)/100 then floor;
    ///  * groups thousands with '.';
    ///  * keeps an explicit fractional part after ',';
    ///  * renders negative values in parentheses.
    public static func number(_ raw: String?) -> String {
        guard var value = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return ""
        }
        if value == "true" || value == "false" { return value }
        var negative = false
        if value.hasPrefix("-") {
            negative = true
            value.removeFirst()
        } else if value.hasPrefix("(") && value.hasSuffix(")") {
            negative = true
            value = String(value.dropFirst().dropLast())
        }
        var integerPart = value
        var fraction = ""
        if let dot = value.firstIndex(of: ".") {
            integerPart = String(value[..<dot])
            fraction = String(value[value.index(after: dot)...])
        }
        // run.html's .number pass splits the fraction BEFORE the integer
        // rounding step. Including the fraction here incorrectly turns
        // 1234.999 into 1.235,999 instead of the observed 1.234,999.
        guard let numeric = Double(integerPart), numeric.isFinite else {
            return raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        }
        let roundedHundredths = floor(numeric * 100 + 0.50000000001)
        let roundedInteger = floor(roundedHundredths / 100)
        var digits = String(format: "%.0f", roundedInteger)
        if digits == "-0" { digits = "0" }
        var grouped = ""
        for (index, ch) in digits.enumerated() {
            if index > 0 && (digits.count - index) % 3 == 0 { grouped.append(".") }
            grouped.append(ch)
        }
        if !fraction.isEmpty { grouped += "," + fraction }
        if negative && grouped != "0" { grouped = "(\(grouped))" }
        return grouped
    }

    public static func date(_ raw: String?) -> String {
        guard let raw = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else { return "" }
        let formats = ["yyyy-MM-dd'T'HH:mm:ss", "yyyy-MM-dd", "dd/MM/yyyy", "dd-MM-yyyy", "yyyyMMdd"]
        for format in formats {
            let f = DateFormatter()
            f.locale = Locale(identifier: "en_US_POSIX")
            f.timeZone = TimeZone(secondsFromGMT: 0)
            f.dateFormat = format
            if let date = f.date(from: raw) {
                let out = DateFormatter()
                out.locale = Locale(identifier: "vi_VN")
                out.dateFormat = "dd/MM/yyyy"
                return out.string(from: date)
            }
        }
        return raw
    }

    /// Mirrors the `ihtkk:kyTinhThue` helper used by the official templates.
    ///
    /// Monthly, quarterly and yearly declarations always print their period as
    /// text ("Tháng 06 năm 2025"), even when `kyKKhaiTuNgay`/`kyKKhaiDenNgay`
    /// are present. The explicit date range is only used when the registry does
    /// not provide a recognised `kieuKy`. This matches the Windows reference
    /// rendering for 01/GTGT (`[01b] Tháng 06 năm 2025`) and 03/TNDN
    /// (`[01] Năm 2024`).
    public static func period(type: String?, period: String?, from: String?, to: String?) -> String {
        if let period, !period.isEmpty {
            switch type {
            case "M":
                let parts = period.split(separator: "/")
                if parts.count == 2 { return "Tháng \(parts[0]) năm \(parts[1])" }
                return period
            case "Q":
                let parts = period.split(separator: "/")
                if parts.count == 2 { return "Quý \(parts[0]) năm \(parts[1])" }
                return period
            case "Y":
                return "Năm \(period)"
            default:
                break
            }
        }
        if let from, !from.isEmpty, let to, !to.isEmpty {
            return "Từ ngày \(date(from)) đến ngày \(date(to))"
        }
        return period ?? ""
    }

    public static func filingTypeLabel(_ type: String?, supplement: String?) -> String {
        switch type {
        case "C": return "Lần đầu: [X]    Bổ sung lần thứ: [ ]"
        case "B": return "Lần đầu: [ ]    Bổ sung lần thứ: [\(supplement ?? "")]"
        default: return ""
        }
    }

    public static func htmlEscape(_ value: String) -> String {
        var s = value
        s = s.replacingOccurrences(of: "&", with: "&amp;")
        s = s.replacingOccurrences(of: "<", with: "&lt;")
        s = s.replacingOccurrences(of: ">", with: "&gt;")
        s = s.replacingOccurrences(of: "\"", with: "&quot;")
        s = s.replacingOccurrences(of: "'", with: "&#39;")
        return s
    }
}

import AppKit

/// One configuration for the app and native QA, independent of a previous job's
/// page range or PDF destination. Never mutate the user's shared print info.
@MainActor
public enum NativePrintSettings {
    public static func make(orientation: PageOrientation, savingTo url: URL? = nil,
                            base: NSPrintInfo? = nil) -> NSPrintInfo {
        let info = (base ?? NSPrintInfo.shared).copy() as! NSPrintInfo
        let mm = 72.0 / 25.4
        info.paperSize = NSSize(width: 210 * mm, height: 297 * mm)
        info.orientation = orientation == .landscape ? .landscape : .portrait
        info.topMargin = 20 * mm
        info.leftMargin = 20 * mm
        info.rightMargin = 20 * mm
        info.bottomMargin = 10 * mm
        info.horizontalPagination = .fit
        info.verticalPagination = .automatic
        info.isHorizontallyCentered = true
        info.isVerticallyCentered = false
        // A prior print-panel page selection must not truncate a PDF export.
        info.dictionary().removeObject(forKey: NSPrintInfo.AttributeKey.firstPage)
        info.dictionary().removeObject(forKey: NSPrintInfo.AttributeKey.lastPage)
        info.dictionary()[NSPrintInfo.AttributeKey.allPages] = true
        info.jobDisposition = url == nil ? .spool : .save
        info.dictionary().removeObject(forKey: NSPrintInfo.AttributeKey.jobSavingURL)
        if let url { info.dictionary()[NSPrintInfo.AttributeKey.jobSavingURL] = url }
        return info
    }
}

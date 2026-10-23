import AppKit

/// Runs the native print sheet without blocking WebKit's main-thread replies.
/// The job object remains alive across the continuation until AppKit finishes.
@MainActor
public final class NativePrintJob: NSObject {
    private var continuation: CheckedContinuation<Bool, Never>?

    public static func run(_ operation: NSPrintOperation, for window: NSWindow) async -> Bool {
        let job = NativePrintJob()
        return await job.perform(operation, for: window)
    }

    private func perform(_ operation: NSPrintOperation, for window: NSWindow) async -> Bool {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            operation.runModal(for: window, delegate: self,
                               didRun: #selector(didFinish(_:success:contextInfo:)), contextInfo: nil)
        }
    }

    @objc private func didFinish(_ operation: NSPrintOperation, success: Bool,
                                 contextInfo: UnsafeMutableRawPointer?) {
        let pending = continuation
        continuation = nil
        pending?.resume(returning: success)
    }
}

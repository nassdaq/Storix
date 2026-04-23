import Foundation
import AppKit

@MainActor
public final class MenuBarController {
    private var statusItem: NSStatusItem?

    public init() {}

    public func install() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(systemSymbolName: "internaldrive", accessibilityDescription: "Storix")
        item.button?.toolTip = "Storix — storage cleaner"
        self.statusItem = item
    }

    public func updateTitle(freeBytes: Int64) {
        let free = ByteCountFormatter.string(fromByteCount: freeBytes, countStyle: .file)
        statusItem?.button?.title = "  \(free) free"
    }

    public func uninstall() {
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
        }
    }

    /// Free bytes on the user's boot volume.
    public static func freeBootVolumeBytes() -> Int64 {
        let home = URL(fileURLWithPath: NSHomeDirectory())
        let values = try? home.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
        return Int64(values?.volumeAvailableCapacityForImportantUsage ?? 0)
    }
}

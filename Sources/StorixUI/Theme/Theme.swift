import SwiftUI

/// Storix neon palette. Dark background, violet → cyan → green ramp.
public enum Theme {
    public static let background = Color(hex: 0x0A0A0F)
    public static let surface    = Color(hex: 0x13131A)
    public static let surfaceAlt = Color(hex: 0x1A1A24)
    public static let border     = Color(hex: 0x27273A)

    public static let textPrimary   = Color(hex: 0xF4F4F5)
    public static let textSecondary = Color(hex: 0xA1A1AA)
    public static let textTertiary  = Color(hex: 0x71717A)

    public static let accent  = Color(hex: 0x7C3AED)
    public static let accent2 = Color(hex: 0x3B82F6)
    public static let accent3 = Color(hex: 0x06B6D4)
    public static let accent4 = Color(hex: 0x10B981)

    public static let danger  = Color(hex: 0xEF4444)
    public static let warning = Color(hex: 0xF59E0B)
    public static let success = Color(hex: 0x10B981)

    /// Ramp used by the sunburst renderer — map bytes → ramp position.
    public static let sizeRamp: [Color] = [
        Color(hex: 0x7C3AED), // largest
        Color(hex: 0x6366F1),
        Color(hex: 0x3B82F6),
        Color(hex: 0x0EA5E9),
        Color(hex: 0x06B6D4),
        Color(hex: 0x14B8A6),
        Color(hex: 0x10B981)  // smallest
    ]

    public static func colorForSize(_ bytes: Int64, maxBytes: Int64) -> Color {
        guard maxBytes > 0 else { return accent4 }
        let ratio = min(1.0, Double(bytes) / Double(maxBytes))
        let idx = Int((1.0 - ratio) * Double(sizeRamp.count - 1))
        return sizeRamp[idx]
    }

    public enum Radius {
        public static let small: CGFloat = 6
        public static let medium: CGFloat = 10
        public static let large: CGFloat = 16
    }

    public enum Spacing {
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 12
        public static let lg: CGFloat = 20
        public static let xl: CGFloat = 32
    }
}

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8)  & 0xFF) / 255.0
        let b = Double(hex & 0xFF)         / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1.0)
    }
}

import SwiftUI
import AppKit

public struct VisualEffectView: NSViewRepresentable {
    public let material: NSVisualEffectView.Material
    public let blendingMode: NSVisualEffectView.BlendingMode
    
    public init(material: NSVisualEffectView.Material = .sidebar, 
                blendingMode: NSVisualEffectView.BlendingMode = .behindWindow) {
        self.material = material
        self.blendingMode = blendingMode
    }
    
    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

public struct AstroTheme {
    // Quantum Blue Palette
    public static let background = Color(red: 0.02, green: 0.03, blue: 0.05)
    public static let accentBlue = Color(red: 0.0, green: 0.8, blue: 1.0) // Electric Cyan
    public static let lightBlue = Color(red: 0.4, green: 0.9, blue: 1.0)
    public static let deepBlue = Color(red: 0.0, green: 0.2, blue: 0.5)
    
    public static let primaryGradient = LinearGradient(
        colors: [accentBlue, Color(red: 0.0, green: 0.4, blue: 0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let darkGradient = LinearGradient(
        colors: [Color(red: 0.05, green: 0.07, blue: 0.1), Color(red: 0.02, green: 0.03, blue: 0.05)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    public static let gaugeBackground = Color(white: 0.1)
    public static let textPrimary = Color.white
    public static let textSecondary = Color.white.opacity(0.7)
    
    public static func cardBackground() -> some View {
        VisualEffectView(material: .fullScreenUI, blendingMode: .withinWindow)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(accentBlue.opacity(0.3), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.6), radius: 15, x: 0, y: 8)
    }
}

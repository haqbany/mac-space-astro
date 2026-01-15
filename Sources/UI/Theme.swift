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
    // Red Edition Palette
    public static let background = Color(red: 0.06, green: 0.04, blue: 0.04)
    public static let accentRed = Color(red: 0.82, green: 0.01, blue: 0.01) // Guards Red
    public static let lightRed = Color(red: 1.0, green: 0.2, blue: 0.2)
    public static let deepRed = Color(red: 0.5, green: 0.0, blue: 0.0)
    
    public static let primaryGradient = LinearGradient(
        colors: [accentRed, Color(red: 0.6, green: 0.0, blue: 0.0)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let darkGradient = LinearGradient(
        colors: [Color(red: 0.12, green: 0.08, blue: 0.08), Color(red: 0.06, green: 0.04, blue: 0.04)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    public static let gaugeBackground = Color(white: 0.12)
    public static let textPrimary = Color.white
    public static let textSecondary = Color.white.opacity(0.6)
    
    public static func cardBackground() -> some View {
        VisualEffectView(material: .fullScreenUI, blendingMode: .withinWindow)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(accentRed.opacity(0.2), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
    }
}

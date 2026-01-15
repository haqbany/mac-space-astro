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
    public static let background = Color(white: 0.05)
    public static let accentColor = Color(red: 0.82, green: 0.01, blue: 0.01) // Guards Red
    public static let gaugeBackground = Color(white: 0.1)
    public static let textPrimary = Color.white
    public static let textSecondary = Color.gray
    
    public static func cardBackground() -> some View {
        VisualEffectView(material: .fullScreenUI, blendingMode: .withinWindow)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
    }
}

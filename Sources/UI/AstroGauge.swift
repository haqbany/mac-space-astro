import SwiftUI

public struct AstroGauge: View {
    let value: Double
    let label: String
    let unit: String
    let maxValue: Double
    let redline: Double
    
    @State private var animatedValue: Double = 0
    
    public init(value: Double, label: String, unit: String, maxValue: Double = 100, redline: Double = 80) {
        self.value = value
        self.label = label
        self.unit = unit
        self.maxValue = maxValue
        self.redline = redline
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // Outer Bezel
                Circle()
                    .strokeBorder(
                        LinearGradient(colors: [.white.opacity(0.2), .black.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 4
                    )
                    .background(Circle().fill(Color(white: 0.05)))
                    .frame(width: 200, height: 200)
                    .shadow(color: .black.opacity(0.8), radius: 10, x: 5, y: 10)
                
                // Dial Plate with Radial Gradient
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [Color(white: 0.12), Color(white: 0.05)]),
                            center: .center,
                            startRadius: 20,
                            endRadius: 100
                        )
                    )
                    .frame(width: 190, height: 190)
                
                // Ticks
                GaugeTicks(maxValue: maxValue, redline: redline)
                
                // Digital Readout (Modern Porsche style)
                VStack(spacing: -2) {
                    Spacer(minLength: 120)
                    Text("\(Int(animatedValue))")
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    Text(unit)
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.gray)
                        .kerning(1.5)
                }
                
                // Needle Shadow (Offset for depth)
                Needle()
                    .fill(Color.black.opacity(0.4))
                    .frame(width: 3, height: 85)
                    .offset(y: -42)
                    .rotationEffect(.degrees(calculateAngle(for: animatedValue)))
                    .offset(x: 2, y: 2)
                    .blur(radius: 1)
                
                // Main Needle
                Needle()
                    .fill(
                        LinearGradient(
                            colors: [AstroTheme.accentBlue, AstroTheme.lightBlue],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 4, height: 90)
                    .offset(y: -45)
                    .rotationEffect(.degrees(calculateAngle(for: animatedValue)))
                
                // Center Hub (Chronograph style)
                ZStack {
                    Circle()
                        .fill(Color(white: 0.15))
                        .frame(width: 20, height: 20)
                        .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
                    Circle()
                        .fill(AstroTheme.accentBlue)
                        .frame(width: 4, height: 4)
                }
                
                // Glass Reflection
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.08), .clear, .white.opacity(0.02)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 190, height: 190)
                    .allowsHitTesting(false)
            }
            .frame(width: 210, height: 210)
            
            Text(label)
                .font(.system(size: 13, weight: .black, design: .default))
                .foregroundColor(.white.opacity(0.8))
                .kerning(2)
        }
        .onAppear {
            withAnimation(.interpolatingSpring(stiffness: 60, damping: 10)) {
                animatedValue = value
            }
        }
        .onChange(of: value) { newValue in
            withAnimation(.interpolatingSpring(stiffness: 60, damping: 10)) {
                animatedValue = newValue
            }
        }
    }
    
    private func calculateAngle(for val: Double) -> Double {
        let percent = min(max(val / maxValue, 0), 1)
        return -130 + (260 * percent)
    }
}

struct GaugeTicks: View {
    let maxValue: Double
    let redline: Double
    
    var body: some View {
        ZStack {
            ForEach(0..<41) { i in
                let angle = Double(i) * 6.5 - 130
                let isMajor = i % 5 == 0
                let isRedline = Double(i) * (maxValue / 40.0) >= redline
                
                TickMark(isMajor: isMajor, color: isRedline ? AstroTheme.accentBlue : .white.opacity(isMajor ? 0.6 : 0.2))
                    .rotationEffect(.degrees(angle))
            }
        }
    }
}

struct TickMark: View {
    let isMajor: Bool
    let color: Color
    
    var body: some View {
        VStack {
            Rectangle()
                .fill(color)
                .frame(width: isMajor ? 2.5 : 1, height: isMajor ? 14 : 7)
            Spacer()
        }
        .frame(height: 180)
    }
}

struct Needle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

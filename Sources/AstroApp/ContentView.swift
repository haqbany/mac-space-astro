import SwiftUI
import AstroUI

public struct ContentView: View {
    @State private var selectedTab: Int = 0
    
    public init() {}
    
    public var body: some View {
        NavigationSplitView {
            List(selection: $selectedTab) {
                NavigationLink(value: 0) {
                    Label("Dashboard", systemImage: "speedometer")
                }
                .tag(0)
                
                NavigationLink(value: 1) {
                    Label("Cleanup", systemImage: "broom")
                }
                .tag(1)
                
                NavigationLink(value: 2) {
                    Label("Astro Chat", systemImage: "sparkles")
                }
                .tag(2)
            }
            .listStyle(.sidebar)
            .navigationTitle("Mac Space Astro")
        } detail: {
            switch selectedTab {
            case 0:
                DashboardView()
            case 1:
                CleanupView()
            case 2:
                AstroChatView()
            default:
                DashboardView()
            }
        }
        .frame(minWidth: 950, minHeight: 650)
        .preferredColorScheme(.dark)
    }
}

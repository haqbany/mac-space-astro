import SwiftUI
import CleanupEngine

public class CleanupViewModel: ObservableObject {
    @Published public var items: [CleanupItem] = []
    @Published public var isScanning = false
    @Published public var selectedItems: Set<UUID> = []
    
    private let engine = CleanupEngine()
    
    public init() {}
    
    public func startScan() async {
        DispatchQueue.main.async { self.isScanning = true }
        let results = await engine.scan(categories: CleanupCategory.allCases)
        DispatchQueue.main.async {
            self.items = results
            self.isScanning = false
        }
    }
    
    public func performCleanup() async {
        let toCleanup = items.filter { selectedItems.contains($0.id) }
        do {
            _ = try await engine.cleanup(items: toCleanup, dryRun: false)
            await startScan()
        } catch {
            print("Cleanup failed")
        }
    }
}

public struct CleanupView: View {
    @StateObject var viewModel = CleanupViewModel()
    
    public init() {}
    
    public var body: some View {
        VStack {
            if viewModel.items.isEmpty && !viewModel.isScanning {
                VStack(spacing: 16) {
                    Image(systemName: "broom")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("Ready for a safety scan?")
                        .font(.headline)
                    Button("Scan Library") {
                        Task { await viewModel.startScan() }
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(AstroTheme.primaryGradient)
                    .cornerRadius(12)
                    .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.isScanning {
                ProgressView("Scanning system paths...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(CleanupCategory.allCases, id: \.self) { category in
                        let categoryItems = viewModel.items.filter { $0.category == category }
                        if !categoryItems.isEmpty {
                            Section(header: Text(category.rawValue)) {
                                ForEach(categoryItems) { item in
                                    CleanupItemRow(item: item, isSelected: viewModel.selectedItems.contains(item.id)) {
                                        if viewModel.selectedItems.contains(item.id) {
                                            viewModel.selectedItems.remove(item.id)
                                        } else {
                                            viewModel.selectedItems.insert(item.id)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                HStack {
                    Text("\(viewModel.selectedItems.count) items selected")
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Cleanup") {
                        Task { await viewModel.performCleanup() }
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(AnyView(viewModel.selectedItems.isEmpty ? AnyView(Color.gray.opacity(0.3)) : AnyView(AstroTheme.primaryGradient)))
                    .cornerRadius(10)
                    .foregroundColor(.white)
                    .disabled(viewModel.selectedItems.isEmpty)
                }
                .padding()
                .background(AstroTheme.cardBackground())
            }
        }
    }
}

struct CleanupItemRow: View {
    let item: CleanupItem
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        HStack {
            Toggle("", isOn: Binding(get: { isSelected }, set: { _ in action() }))
                .labelsHidden()
            
            VStack(alignment: .leading) {
                Text(item.path.lastPathComponent)
                    .font(.body)
                Text(item.path.path)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(item.formattedSize)
                    .font(.system(.body, design: .monospaced))
                Text(item.category.riskLevel.rawValue)
                    .font(.caption2)
                    .padding(.horizontal, 4)
                    .background(riskColor(item.category.riskLevel).opacity(0.2))
                    .foregroundColor(riskColor(item.category.riskLevel))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }
    
    func riskColor(_ level: RiskLevel) -> Color {
        switch level {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}

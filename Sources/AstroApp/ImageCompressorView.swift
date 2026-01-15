import SwiftUI
import AppKit
import ImageEngine
import AstroUI

public struct ImageCompressorView: View {
    @StateObject private var viewModel = ImageCompressorViewModel()
    
    public init() {}
    
    public var body: some View {
        ZStack {
            AstroTheme.darkGradient
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(AstroTheme.accentBlue.opacity(0.1))
                            .frame(width: 60, height: 60)
                        Image(systemName: viewModel.isOptimizing ? "arrow.triangle.2.circlepath" : "photo.stack.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AstroTheme.accentBlue)
                        .rotationEffect(.degrees(viewModel.isOptimizing ? 360 : 0))
                        .animation(viewModel.isOptimizing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: viewModel.isOptimizing)
                }
                
                Text("Astro Image Compressor")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(viewModel.statusMessage)
                    .font(.system(size: 13))
                    .foregroundColor(viewModel.isOptimizing ? .blue : .white.opacity(0.5))
                
                if let lastResult = viewModel.lastResult, !viewModel.isOptimizing {
                    Button(action: {
                        NSWorkspace.shared.activateFileViewerSelecting([lastResult.outputPath])
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "folder.fill.badge.plus")
                                .font(.system(size: 10))
                            Text("Output: \(lastResult.outputPath.lastPathComponent)")
                                .font(.system(size: 10, weight: .medium))
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 10))
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(Color.blue.opacity(0.15))
                        .foregroundColor(.blue)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(.top, 20)
            .animation(.spring(), value: viewModel.lastResult)
            
            // Drop Zone
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 2)
                            .padding(2)
                    )
                
                VStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 30))
                        .foregroundColor(.white.opacity(0.2))
                    
                    Text("Drag & Drop Images or Folders here")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            .frame(height: 200)
            .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                var found = false
                for provider in providers {
                    _ = provider.loadObject(ofClass: URL.self) { url, _ in
                        if let url = url {
                            DispatchQueue.main.async {
                                viewModel.optimizeImages(urls: [url])
                            }
                        }
                    }
                }
                found = true
                return found
            }
            
            // Format Selection
            VStack(alignment: .leading, spacing: 10) {
                Text("TARGET FORMAT")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.4))
                    .kerning(1)
                
                HStack(spacing: 8) {
                    ForEach(viewModel.supportedFormats, id: \.self) { format in
                        Button(action: { viewModel.selectedFormat = format }) {
                            Text(format.rawValue.uppercased())
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(viewModel.selectedFormat == format ? .white : .white.opacity(0.4))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(viewModel.selectedFormat == format ? AstroTheme.accentBlue.opacity(0.3) : Color.white.opacity(0.05))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(viewModel.selectedFormat == format ? AstroTheme.accentBlue.opacity(0.5) : Color.clear, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 4)
            
            // Buttons
            HStack(spacing: 12) {
                Button(action: {
                    let panel = NSOpenPanel()
                    panel.allowsMultipleSelection = true
                    panel.canChooseDirectories = false
                    panel.allowedContentTypes = [.image, .jpeg, .png, .webP, .heic, .heif, .gif, .tiff]
                    if panel.runModal() == .OK {
                        viewModel.optimizeImages(urls: panel.urls)
                    }
                }) {
                    Label("Files", systemImage: "photo")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isOptimizing)
                
                Button(action: {
                    let panel = NSOpenPanel()
                    panel.canChooseFiles = false
                    panel.canChooseDirectories = true
                    panel.allowsMultipleSelection = false
                    if panel.runModal() == .OK {
                        viewModel.optimizeImages(urls: panel.urls)
                    }
                }) {
                    Label("Folder", systemImage: "folder.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(AstroTheme.primaryGradient)
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isOptimizing)
            }
            
            Spacer()
        }
        .padding(24)
        .preferredColorScheme(.dark)
        }
    }
}

class ImageCompressorViewModel: ObservableObject {
    @Published var isOptimizing = false
    @Published var statusMessage = "Waiting for images..."
    @Published var selectedFormat: ImageFormat = .jpeg
    @Published var lastResult: OptimizationResult?
    @Published var supportedFormats: [ImageFormat] = []
    
    let engine = ImageEngine()
    
    init() {
        self.supportedFormats = ImageFormat.allCases.filter { engine.isFormatSupported($0) }
        // Default to a supported format
        if !supportedFormats.contains(.webp) {
            selectedFormat = supportedFormats.first ?? .jpeg
        } else {
            selectedFormat = .webp
        }
    }
    
    func optimizeImages(urls: [URL]) {
        let format = selectedFormat
        Task {
            var allImageURLs: [URL] = []
            let fileManager = FileManager.default
            
            for url in urls {
                var isDirectory: ObjCBool = false
                if fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) {
                    if isDirectory.boolValue {
                        let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles])
                        while let fileURL = enumerator?.nextObject() as? URL {
                            let ext = fileURL.pathExtension.lowercased()
                            if ["jpg", "jpeg", "png", "webp", "avif", "heic", "heif"].contains(ext) {
                                allImageURLs.append(fileURL)
                            }
                        }
                    } else {
                        let ext = url.pathExtension.lowercased()
                        if ["jpg", "jpeg", "png", "webp", "avif", "heic", "heif"].contains(ext) {
                            allImageURLs.append(url)
                        }
                    }
                }
            }
            
            guard !allImageURLs.isEmpty else {
                await MainActor.run { statusMessage = "No images found" }
                return
            }

            let totalImages = allImageURLs.count
            await MainActor.run {
                isOptimizing = true
                statusMessage = "Optimizing \(totalImages) images..."
                NSSound(named: "Pop")?.play()
            }
            
            var totalSaved: Int64 = 0
            var processedCount = 0
            var latestOptimizationResult: OptimizationResult?
            var lastError: String?
            
            for url in allImageURLs {
                do {
                    let result = try await engine.optimize(at: url, targetFormat: format)
                    totalSaved += result.savedBytes
                    processedCount += 1
                    latestOptimizationResult = result
                    
                    if totalImages > 1 {
                        let currentCount = processedCount
                        await MainActor.run {
                            statusMessage = "Processing (\(currentCount)/\(totalImages))..."
                        }
                    }
                } catch {
                    lastError = error.localizedDescription
                    print("Optimization failed: \(error)")
                }
            }
            
            let finalSaved = totalSaved
            let finalCount = processedCount
            let lastRes = latestOptimizationResult
            let errorMsg = lastError
            await MainActor.run {
                isOptimizing = false
                lastResult = lastRes
                if finalCount > 0 {
                    statusMessage = "Done! Saved \(ByteCountFormatter.string(fromByteCount: finalSaved, countStyle: .file)) across \(finalCount) images."
                } else if let errorMsg = errorMsg {
                    statusMessage = errorMsg
                } else {
                    statusMessage = "Optimization failed"
                }
                NSSound(named: finalCount > 0 ? "Glass" : "Basso")?.play()
            }
            
            try? await Task.sleep(nanoseconds: 8 * 1_000_000_000)
            await MainActor.run { if !isOptimizing { statusMessage = "Ready for more" } }
        }
    }
}

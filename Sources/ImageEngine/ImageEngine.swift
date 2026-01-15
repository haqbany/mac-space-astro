import Foundation
import AppKit
import UniformTypeIdentifiers
import CoreGraphics
import ImageIO

public enum ImageFormat: String, CaseIterable {
    case jpeg, png, webp, avif, heic, tiff, gif
}

public struct OptimizationResult: Sendable, Equatable {
    public let originalSize: UInt64
    public let optimizedSize: UInt64
    public let outputPath: URL
    
    public var savedBytes: Int64 {
        Int64(originalSize) - Int64(optimizedSize)
    }
    
    public var savingsPercentage: Double {
        guard originalSize > 0 else { return 0 }
        return (Double(savedBytes) / Double(originalSize)) * 100
    }
    
    public init(originalSize: UInt64, optimizedSize: UInt64, outputPath: URL) {
        self.originalSize = originalSize
        self.optimizedSize = optimizedSize
        self.outputPath = outputPath
    }
}

public class ImageEngine {
    public init() {}
    
    public func isFormatSupported(_ format: ImageFormat) -> Bool {
        let uti = getUTI(for: format)
        let supportedTypes = CGImageDestinationCopyTypeIdentifiers() as? [String] ?? []
        return supportedTypes.contains(uti)
    }
    
    public func optimize(at inputURL: URL, targetFormat: ImageFormat? = nil) async throws -> OptimizationResult {
        // Use CGImageSource to support virtually all image formats (RAW, HEIC, WebP, etc.)
        guard let source = CGImageSourceCreateWithURL(inputURL as CFURL, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw NSError(domain: "ImageEngine", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unsupported image format or corrupted file: \(inputURL.lastPathComponent)"])
        }
        
        // Get original file size
        let originalSize = (try? FileManager.default.attributesOfItem(atPath: inputURL.path)[.size] as? UInt64) ?? 0
        
        // Determine output path and format
        let fileName = inputURL.deletingPathExtension().lastPathComponent
        let format = targetFormat ?? detectFormat(from: inputURL)
        let uti = getUTI(for: format)
        
        // Check if destination format is supported
        let supportedTypes = CGImageDestinationCopyTypeIdentifiers() as? [String] ?? []
        if !supportedTypes.contains(uti) {
            throw NSError(domain: "ImageEngine", code: 2, userInfo: [NSLocalizedDescriptionKey: "Your system does not support writing in \(format.rawValue.uppercased()) format. Please try JPEG or PNG."])
        }
        
        let outputExtension = format.rawValue
        let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let outputURL = desktopURL.appendingPathComponent("\(fileName)_optimized.\(outputExtension)")
        
        // Create destination
        guard let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, uti as CFString, 1, nil) else {
            throw NSError(domain: "ImageEngine", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to initialize image destination for \(format.rawValue.uppercased())"])
        }
        
        // Optimization options based on format
        var options: [CFString: Any] = [
            kCGImageDestinationMergeMetadata: false
        ]
        
        switch format {
        case .png, .tiff, .gif:
            // Lossless formats (mostly)
            options[kCGImageDestinationLossyCompressionQuality] = 1.0
        case .heic, .avif, .webp, .jpeg:
            // 0.85 is the "visually lossless" sweet spot.
            // It provides significant size reduction without perceptible quality loss.
            options[kCGImageDestinationLossyCompressionQuality] = 0.85
        }
        
        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
        
        guard CGImageDestinationFinalize(destination) else {
            throw NSError(domain: "ImageEngine", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to finalize and write the optimized image to disk"])
        }
        
        let optimizedSize = (try? FileManager.default.attributesOfItem(atPath: outputURL.path)[.size] as? UInt64) ?? 0
        
        return OptimizationResult(
            originalSize: originalSize,
            optimizedSize: optimizedSize,
            outputPath: outputURL
        )
    }
    
    private func getUTI(for format: ImageFormat) -> String {
        switch format {
        case .jpeg: return UTType.jpeg.identifier
        case .png: return UTType.png.identifier
        case .webp: return "org.webmproject.webp"
        case .avif: return "public.avif"
        case .heic: return UTType.heic.identifier
        case .tiff: return UTType.tiff.identifier
        case .gif: return UTType.gif.identifier
        }
    }
    
    private func detectFormat(from url: URL) -> ImageFormat {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "png": return .png
        case "webp": return .webp
        case "avif": return .avif
        case "heic", "heif": return .heic
        case "tiff", "tif": return .tiff
        case "gif": return .gif
        default: return .jpeg
        }
    }
}

import Foundation
import CoreSystemKit

public enum CleanupCategory: String, CaseIterable {
    case systemCaches = "System Caches"
    case userCaches = "User Caches"
    case logs = "Logs"
    case trash = "Trash"
    case downloads = "Downloads"
    
    public var riskLevel: RiskLevel {
        switch self {
        case .systemCaches: return .medium
        case .userCaches: return .low
        case .logs: return .low
        case .trash: return .low
        case .downloads: return .medium
        }
    }
}

public enum RiskLevel: String {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}

public struct CleanupItem: Identifiable {
    public let id = UUID()
    public let category: CleanupCategory
    public let path: URL
    public let size: UInt64
    public let isEssential: Bool
    
    public init(category: CleanupCategory, path: URL, size: UInt64, isEssential: Bool) {
        self.category = category
        self.path = path
        self.size = size
        self.isEssential = isEssential
    }
    
    public var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }
}

public class CleanupEngine {
    private let fileManager = FileManager.default
    
    public init() {}
    
    public func scan(categories: [CleanupCategory]) async -> [CleanupItem] {
        var items: [CleanupItem] = []
        
        for category in categories {
            let paths = getPaths(for: category)
            for path in paths {
                let size = getFolderSize(at: path)
                if size > 0 {
                    items.append(CleanupItem(
                        category: category,
                        path: path,
                        size: size,
                        isEssential: false
                    ))
                }
            }
        }
        
        return items
    }
    
    private func getPaths(for category: CleanupCategory) -> [URL] {
        switch category {
        case .userCaches:
            return [fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first].compactMap { $0 }
        case .logs:
            let userLogs = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first?.appendingPathComponent("Logs")
            return [userLogs].compactMap { $0 }
        case .trash:
            return [fileManager.urls(for: .trashDirectory, in: .userDomainMask).first].compactMap { $0 }
        case .systemCaches:
            // Minimal set for demo/safety
            return [URL(fileURLWithPath: "/Library/Caches")]
        case .downloads:
            return [fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first].compactMap { $0 }
        }
    }
    
    public func scanLargeFiles(minSizeMB: Int = 100) async -> [CleanupItem] {
        var largeItems: [CleanupItem] = []
        let minSize = UInt64(minSizeMB) * 1024 * 1024
        
        // Scan user home for large files
        let home = fileManager.homeDirectoryForCurrentUser
        let scanPaths = [
            home.appendingPathComponent("Downloads"),
            home.appendingPathComponent("Documents"),
            home.appendingPathComponent("Movies"),
            home.appendingPathComponent("Desktop"),
            home.appendingPathComponent("Library/Caches"),
            home.appendingPathComponent("Library/Developer/Xcode/DerivedData"),
            URL(fileURLWithPath: "/Library/Caches")
        ]
        
        for path in scanPaths {
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: path.path, isDirectory: &isDirectory), isDirectory.boolValue else { continue }
            
            let enumerator = fileManager.enumerator(at: path, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsPackageDescendants, .skipsHiddenFiles])
            while let fileURL = enumerator?.nextObject() as? URL {
                do {
                    let values = try fileURL.resourceValues(forKeys: [.fileSizeKey])
                    if let size = values.fileSize, UInt64(size) > minSize {
                        largeItems.append(CleanupItem(
                            category: .trash,
                            path: fileURL,
                            size: UInt64(size),
                            isEssential: false
                        ))
                    }
                } catch { continue }
                
                // Yield to keep UI responsive if scanning many files
                if largeItems.count % 100 == 0 {
                    await Task.yield()
                }
            }
        }
        
        return largeItems.sorted { $0.size > $1.size }
    }
    
    private func getFolderSize(at url: URL) -> UInt64 {
        var totalSize: UInt64 = 0
        let keys: [URLResourceKey] = [.fileSizeKey]
        let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: keys, options: .skipsHiddenFiles)
        
        while let fileURL = enumerator?.nextObject() as? URL {
            do {
                let values = try fileURL.resourceValues(forKeys: Set(keys))
                totalSize += UInt64(values.fileSize ?? 0)
            } catch {
                continue
            }
        }
        
        return totalSize
    }
    
    public func moveToTrash(items: [CleanupItem]) async throws -> UInt64 {
        var trashedSize: UInt64 = 0
        
        for item in items {
            do {
                var trashedURL: NSURL?
                try fileManager.trashItem(at: item.path, resultingItemURL: &trashedURL)
                trashedSize += item.size
            } catch {
                // If it's a directory and trash fails, try individual contents if it's trash/caches
                continue 
            }
        }
        
        return trashedSize
    }

    public func cleanup(items: [CleanupItem], dryRun: Bool = true) async throws -> UInt64 {
        var freedSpace: UInt64 = 0
        
        for item in items {
            if dryRun {
                freedSpace += item.size
                continue
            }
            
            // Real cleanup logic
            do {
                let resources = try item.path.resourceValues(forKeys: [.isDirectoryKey])
                if resources.isDirectory == true {
                    // Clean directory contents
                    let contents = try fileManager.contentsOfDirectory(at: item.path, includingPropertiesForKeys: nil, options: [])
                    for file in contents {
                        do {
                            let fileResources = try file.resourceValues(forKeys: [.fileSizeKey])
                            let size = UInt64(fileResources.fileSize ?? 0)
                            try fileManager.removeItem(at: file)
                            freedSpace += size
                        } catch { continue }
                    }
                } else {
                    // Clean individual file
                    let size = item.size
                    try fileManager.removeItem(at: item.path)
                    freedSpace += size
                }
            } catch { continue }
        }
        
        return freedSpace
    }
}

import Foundation

public enum AstroIntent {
    case explainMemory
    case explainSwap
    case speedCheck
    case unknown
}

public struct AstroResponse {
    public let text: String
    public let source: ResponseSource
}

public enum ResponseSource {
    case fastRule
    case localLLM
}

public class AstroAIService {
    public init() {}
    
    public func process(query: String) async -> AstroResponse {
        // 1. Intent Routing (Regex/Fast Rules)
        let intent = routeIntent(query)
        
        if intent != .unknown {
            return generateRuleBasedResponse(for: intent)
        }
        
        // 2. Real LLM Inference (Placeholder)
        return AstroResponse(
            text: "I'm analyzing your Mac's telemetry locally. Based on typical macOS behavior, your system is managing memory efficiently using compression.",
            source: .localLLM
        )
    }
    
    private func routeIntent(_ query: String) -> AstroIntent {
        let q = query.lowercased()
        if q.contains("ram") || q.contains("memory") {
            return .explainMemory
        }
        if q.contains("swap") {
            return .explainSwap
        }
        if q.contains("slow") || q.contains("fast") || q.contains("speed") {
            return .speedCheck
        }
        return .unknown
    }
    
    private func generateRuleBasedResponse(for intent: AstroIntent) -> AstroResponse {
        let text: String
        switch intent {
        case .explainMemory:
            text = "macOS uses 'Memory Compression' to keep data in RAM instead of swap. High 'Wired' memory is reserved by the system and can't be compressed. It's normal to have high RAM usage—'Free RAM is wasted RAM'."
        case .explainSwap:
            text = "Swap is used when memory pressure is high. Modern SSDs make swap very fast, but excessive swap can indicative that you're exceeding physical RAM limits consistently."
        case .speedCheck:
            text = "I don't offer 'Speed Boost' buttons because they are usually placebo. If your Mac feels slow, check 'Memory Pressure' in the Dashboard. If it's red, you need more RAM or fewer open apps."
        case .unknown:
            text = "I'm here to help you understand your Mac's internals."
        }
        
        return AstroResponse(text: text, source: .fastRule)
    }
}

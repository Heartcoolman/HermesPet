import Foundation

/// CLI 模式（Claude Code / Codex）的自动模型档位。
///
/// **为什么不暴露 picker UI**：上游维护者明确反对让用户选模型字符串
/// —— 怕新手选到 haiku / mini 这类轻量款，回答质量下降反而扣在产品头上。
/// 这里只复用 directAPI 已有的 fast / balanced / deep 三档心智（见 `DirectResponsePreference`），
/// 内部根据信号自动判定档位，UI 不展示，新手零感知。
///
/// **决策优先级**：附件 > 关键词 > 长度。
/// **balanced 不传 `--model`**：沿用 CLI 自身默认，是 owner 顾虑「错误溯源成本」的兜底
/// —— CLI 之后改默认我们不需要跟改，传错模型也不会以「AI 莫名失败」的形式暴露。
enum CLIModelTier: String {
    case fast
    case balanced
    case deep

    /// Claude CLI `--model` 参数值。`nil` = 不传 `--model`，由 CLI 自己决定。
    /// 用 `haiku` / `opus` 别名（不写死版本号），CLI 升级自动跟随各档对应的新版本。
    var claudeModel: String? {
        switch self {
        case .fast:     return "haiku"
        case .balanced: return nil          // sonnet 是 CLI 当前默认
        case .deep:     return "opus"
        }
    }

    /// Codex CLI `--model` 参数值。`nil` = 不传 `--model`。
    /// 模型 ID 以 2026-05 OpenAI 官方 codex 文档为准；balanced 不传让 CLI 自己跟默认。
    var codexModel: String? {
        switch self {
        case .fast:     return "gpt-5.4-mini"
        case .balanced: return nil          // gpt-5.4 是 CLI 当前默认
        case .deep:     return "gpt-5.4-codex"
        }
    }

    /// 根据最近一条 user 消息自动判定档位。被 ChatViewModel 在 spawn 前调用。
    ///
    /// 没有 user 消息（quickAsk 前的边缘场景等）一律 balanced。
    static func decide(messages: [ChatMessage]) -> CLIModelTier {
        guard let latest = messages.last(where: { $0.role == .user }) else {
            return .balanced
        }
        // 1. 附件优先：拖入文档 / 多图 → 任务规模够大，直接走 deep
        if !latest.documentPaths.isEmpty { return .deep }
        if latest.images.count >= 2 || latest.imagePaths.count >= 2 { return .deep }

        // 2. 关键词信号：用户主动要求「详细 / 深入」走 deep；「概括 / 一句话」走 fast
        let text = latest.content
        if Self.containsAny(text, of: Self.deepKeywords) { return .deep }
        if Self.containsAny(text, of: Self.fastKeywords) { return .fast }

        // 3. 长度兜底：短 → fast；中 → balanced（不传 --model）；长 → deep
        switch text.count {
        case ..<200:  return .fast
        case ..<1500: return .balanced
        default:      return .deep
        }
    }

    /// 升档关键词。中英混排（用户可能用 GPT/Claude 的英文术语提问）。
    private static let deepKeywords: [String] = [
        "详细", "深入", "深度", "完整分析", "全面",
        "重构", "排查", "找原因", "复盘",
        "root cause", "in depth", "thorough", "step by step", "step-by-step"
    ]

    /// 降档关键词。
    private static let fastKeywords: [String] = [
        "概括", "简单说", "一句话", "列一下", "简要",
        "tldr", "tl;dr", "in short", "summarize", "brief"
    ]

    private static func containsAny(_ text: String, of keywords: [String]) -> Bool {
        let lower = text.lowercased()
        for kw in keywords where lower.contains(kw.lowercased()) {
            return true
        }
        return false
    }
}

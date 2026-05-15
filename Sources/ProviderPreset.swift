import Foundation

/// Hermes 模式的"服务商预设" —— 让没装 Claude Code / Codex CLI 的用户
/// 也能开箱即用：选一家服务商，自动填好 baseURL + 推荐模型，只需要再粘 API Key。
///
/// **为什么不在 Hermes 之外单独开一个 AgentMode**：
/// Hermes 模式技术上就是 OpenAI 兼容 HTTP 客户端，换 baseURL 就能直连任何兼容服务商。
/// 多一个枚举会让 ChatViewModel / 持久化 / 灵动岛颜色一堆地方跟着改，没必要。
/// 这里只是把"配置体验"做傻瓜化。
struct ProviderPreset: Identifiable, Hashable {
    let id: String          // UserDefaults 存的预设标识
    let displayName: String // UI 显示名
    let baseURL: String     // OpenAI 兼容 base URL
    let defaultModel: String// 推荐主力模型
    let altModels: [String] // 备选模型（写进 placeholder / 文档提示）
    let signupURL: String?  // 注册 / 获取 API Key 的入口（用户点"如何获取 Key"时跳）

    /// 预设列表 —— 顺序就是 UI 上 Picker 显示的顺序。
    /// 模型字符串以 2026-05 各家官方文档为准。
    static let all: [ProviderPreset] = [
        ProviderPreset(
            id: "deepseek",
            displayName: "DeepSeek",
            baseURL: "https://api.deepseek.com/v1",
            defaultModel: "deepseek-v4-pro",
            altModels: ["deepseek-v4-flash"],
            signupURL: "https://platform.deepseek.com/api_keys"
        ),
        ProviderPreset(
            id: "zhipu",
            displayName: "智谱 GLM",
            baseURL: "https://open.bigmodel.cn/api/paas/v4",
            defaultModel: "glm-5",
            altModels: ["glm-5.1", "glm-5-turbo"],
            signupURL: "https://open.bigmodel.cn/usercenter/apikeys"
        ),
        ProviderPreset(
            id: "moonshot",
            displayName: "Moonshot Kimi",
            baseURL: "https://api.moonshot.cn/v1",
            defaultModel: "kimi-k2.6",
            altModels: ["kimi-k2.5", "kimi-k2"],
            signupURL: "https://platform.moonshot.cn/console/api-keys"
        ),
        ProviderPreset(
            id: "openai",
            displayName: "OpenAI",
            baseURL: "https://api.openai.com/v1",
            defaultModel: "gpt-5.4",
            altModels: ["gpt-5.5", "gpt-5.4-mini"],
            signupURL: "https://platform.openai.com/api-keys"
        )
    ]

    /// 自定义预设 —— 不在 all 里，由 UI 单独追加一项让用户自己填 URL/模型
    static let custom = ProviderPreset(
        id: "custom",
        displayName: "自定义",
        baseURL: "",
        defaultModel: "",
        altModels: [],
        signupURL: nil
    )

    /// 老用户 / 自托管 Hermes Gateway 的兜底预设（baseURL 含 localhost）。
    /// 用户已经配过 http://localhost:8642 的话设置面板会识别成这个。
    static let hermesLocal = ProviderPreset(
        id: "hermes-local",
        displayName: "Hermes Gateway（本地）",
        baseURL: "http://localhost:8642/v1",
        defaultModel: "hermes-agent",
        altModels: [],
        signupURL: nil
    )

    /// 根据当前已存的 baseURL 反查应该选哪个预设（设置面板首次打开时判断当前在用哪家）。
    /// 完全匹配优先；找不到就归到"自定义"，让用户能编辑完整 URL。
    static func detect(baseURL: String) -> ProviderPreset {
        // 归一化：去末尾斜杠，方便匹配（用户可能填 https://api.deepseek.com/v1/）
        let normalized = baseURL.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "/+$", with: "", options: .regularExpression)
        if normalized.isEmpty { return all[0] }   // 全新用户默认第一项
        if normalized.contains("localhost") || normalized.contains("127.0.0.1") {
            return hermesLocal
        }
        for preset in all {
            let presetURL = preset.baseURL.replacingOccurrences(of: "/+$", with: "", options: .regularExpression)
            if normalized == presetURL { return preset }
        }
        return custom
    }
}

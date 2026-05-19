# Security Policy

## 🛡️ 官方版本验证

HermesPet 由 **[Basion (@basionwang-bot)](https://github.com/basionwang-bot)** 独立开发。

### 如何验证你下载的是正版

1. **唯一官方下载源**：[github.com/basionwang-bot/HermesPet/releases](https://github.com/basionwang-bot/HermesPet/releases)
2. **应用内验证**：设置 → 关于 → 官方版本验证 → 显示 Team ID `R34KL4X4D9`
3. **codesign 命令行验证**：
   ```bash
   codesign -dvvv "/Applications/Hermes 桌宠.app" 2>&1 | grep "TeamIdentifier"
   # 正版输出：TeamIdentifier=R34KL4X4D9
   ```

### ⚠️ 警告：非官方渠道风险

从以下渠道获取的 HermesPet **不保证安全**：
- 个人网盘 / 百度云 / 阿里云盘分享
- 二手交易平台（闲鱼、转转等）
- 第三方下载站
- 微信群 / QQ 群分享的安装包
- 任何声称是"破解版"或"修改版"的版本

这些渠道的安装包可能被植入恶意代码，且无法通过 codesign 验证。

---

## 🔐 报告安全漏洞

如果你发现 HermesPet 存在安全漏洞，请**不要**在公开 Issue 中披露。

### 报告方式

1. **邮件报告**（推荐）：发送至 [basionwang@gmail.com](mailto:basionwang@gmail.com)
   - 标题格式：`[SECURITY] 漏洞简述`
   - 内容包含：漏洞描述、复现步骤、影响范围、你的联系方式

2. **GitHub Security Advisory**：通过 [GitHub 安全公告](https://github.com/basionwang-bot/HermesPet/security/advisories/new) 提交

### 响应承诺

- **24 小时内**：确认收到报告
- **72 小时内**：初步评估漏洞严重性
- **7 天内**：提供修复方案或临时缓解措施
- **30 天内**：发布修复版本（严重漏洞会加急）

### 安全更新通知

安全更新会通过以下渠道发布：
- GitHub Releases（标注 `[Security]` 标签）
- 应用内自动更新推送
- 官方网站公告：[hermespet.cc](https://hermespet.cc)

---

## 📋 支持的版本

| 版本 | 安全支持 |
|------|----------|
| v1.2.x（最新） | ✅ 完整支持 |
| v1.1.x | ⚠️ 仅严重漏洞 |
| < v1.1.0 | ❌ 不再支持 |

建议始终使用最新版本以获得最佳安全保护。

---

## 🚨 举报盗用 / 冒名行为

如果你发现有人：
- 声称自己是 HermesPet 的原作者
- 将 HermesPet 重新打包后以其他名义发布
- 在商业场景中使用 HermesPet 但未遵守 Apache 2.0 许可证
- 使用 HermesPet 的名称 / Logo 进行误导性宣传

请通过以下方式举报：
1. 在 [GitHub Issues](https://github.com/basionwang-bot/HermesPet/issues) 中开一个标题带 `[盗用举报]` 的 Issue
2. 或发送邮件至 [basionwang@gmail.com](mailto:basionwang@gmail.com)

提供以下信息有助于快速处理：
- 侵权方的链接 / 截图
- 侵权行为的具体描述
- 发现时间

我们会在确认后采取包括但不限于 DMCA Takedown 在内的法律手段。

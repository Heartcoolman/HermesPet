# 贡献指南 · Contributing Guide

感谢你对 HermesPet 的关注！每一个 Issue、PR、Star 都是对这个独立项目最真实的支持。

---

## 🤝 如何参与

### 报告 Bug

1. 先搜索 [已有 Issues](https://github.com/basionwang-bot/HermesPet/issues) 确认是否已被报告
2. 使用 Issue 模板，提供：
   - macOS 版本 + 芯片类型（Apple Silicon / Intel）
   - HermesPet 版本号（设置 → 关于）
   - 复现步骤（越详细越好）
   - 预期行为 vs 实际行为
   - 如有崩溃，附上崩溃日志（设置 → 关于 → 崩溃日志 → 一键复制）

### 功能建议

- 开一个 Issue，标题带 `[Feature Request]`
- 描述你想要的功能、使用场景、为什么觉得有价值
- 建议先讨论再动手，避免方向不一致

### 提交代码

1. Fork 本仓库
2. 创建功能分支：`git checkout -b feature/your-feature`
3. 提交前确保：
   - 代码能编译通过（`./build.sh` 无报错）
   - 遵循现有代码风格（Swift 6 strict concurrency）
   - 新功能有基本的注释说明
4. 提交 PR，描述你做了什么、为什么这么做

---

## 📜 贡献者许可协议

提交 PR 即表示你同意：

1. 你的贡献以 **Apache License 2.0** 许可发布
2. 你拥有提交代码的合法权利
3. 你的贡献将成为 HermesPet 项目的一部分，版权归属遵循 Apache 2.0 条款
4. 项目维护者（Basion Wang）保留对贡献代码的最终决策权

---

## 🚫 不接受的贡献

- 违反 Apache 2.0 许可证的代码
- 包含恶意代码或后门
- 未经授权使用第三方专有代码
- 与项目方向严重不符的大型重构（请先讨论）

---

## 💡 开发环境

```bash
# 环境要求
macOS 14.0+
Xcode Command Line Tools
Swift 6.0

# 克隆并构建
git clone https://github.com/basionwang-bot/HermesPet.git
cd HermesPet
./build.sh

# 构建 + 安装 + 启动
./install.sh
```

---

## 📞 联系方式

- **Issue 讨论**：[GitHub Issues](https://github.com/basionwang-bot/HermesPet/issues)
- **邮件**：[basionwang@gmail.com](mailto:basionwang@gmail.com)
- **官方网站**：[hermespet.cc](https://hermespet.cc)

---

Made with ✦ by Basion · 感谢每一位贡献者

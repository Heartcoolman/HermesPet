import AppKit
import SwiftUI

/// Apple Intelligence 风格的全屏边缘光环。
/// 按住语音热键时显示，松开时淡出。
/// 配合系统音效，模拟 Siri 召唤的视觉听觉体验。
@MainActor
final class IntelligenceOverlayController {
    static let shared = IntelligenceOverlayController()

    private var window: NSWindow?
    private var hostingView: NSHostingView<IntelligenceGlowView>?

    private init() {}

    func show() {
        if window == nil { createWindow() }
        // 同步把 window 移到当前主屏的 frame，多屏场景也对得上
        if let screen = NSScreen.main {
            window?.setFrame(screen.frame, display: false)
        }
        // 触发视图内 active = true 的 transition 动画
        hostingView?.rootView = IntelligenceGlowView(isActive: true)
        window?.orderFront(nil)

        // 召唤音效 —— 从 UserDefaults 读，用户可在设置中选择 / 关闭
        let soundName = UserDefaults.standard.string(forKey: "voiceStartSound") ?? "Funk"
        if !soundName.isEmpty {
            NSSound(named: soundName)?.play()
        }
    }

    func hide() {
        // 触发淡出 transition；动画结束后真正 orderOut
        hostingView?.rootView = IntelligenceGlowView(isActive: false)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) { [weak self] in
            // 如果在动画期间又 show 了，hostingView 已经是 active=true，就不 hide
            if self?.hostingView?.rootView.isActive == false {
                self?.window?.orderOut(nil)
            }
        }
    }

    private func createWindow() {
        guard let screen = NSScreen.main else { return }
        let w = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        // 跟聊天窗同级（HermesWindowLevel.chat）—— 见 WindowLevels.swift 规范。
        // 不挡灵动岛麦克风脉冲是关键设计点。
        w.level = HermesWindowLevel.intelligence
        w.isOpaque = false
        w.backgroundColor = .clear
        w.hasShadow = false
        w.ignoresMouseEvents = true          // 关键：让用户能正常操作底下的 app
        w.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        w.isReleasedWhenClosed = false

        let host = NSHostingView(rootView: IntelligenceGlowView(isActive: false))
        host.frame = w.contentLayoutRect
        host.autoresizingMask = [.width, .height]
        w.contentView = host

        self.window = w
        self.hostingView = host
    }
}

// MARK: - SwiftUI 光环视图

/// 屏幕边缘流动的 6 色 Apple Intelligence 光环。
/// isActive=true 时显示，false 时 fade out（用 transition 处理）。
struct IntelligenceGlowView: View {
    var isActive: Bool

    /// 主色环 6 个颜色，循环用 —— 直接照搬 SF System Colors
    private static let colors: [Color] = [
        Color(red: 1.00, green: 0.18, blue: 0.33),   // #FF2D55 systemPink
        Color(red: 1.00, green: 0.58, blue: 0.00),   // #FF9500 systemOrange
        Color(red: 1.00, green: 0.80, blue: 0.00),   // #FFCC00 systemYellow
        Color(red: 0.20, green: 0.78, blue: 0.35),   // #34C759 systemGreen
        Color(red: 0.35, green: 0.78, blue: 0.98),   // #5AC8FA systemTeal
        Color(red: 0.69, green: 0.32, blue: 0.87),   // #AF52DE systemPurple
        Color(red: 1.00, green: 0.18, blue: 0.33),   // 闭环回到粉红
    ]

    var body: some View {
        ZStack {
            if isActive {
                AnimatedGlow()
                    .transition(.opacity.combined(with: .scale(scale: 1.05)))
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .animation(AnimTok.smooth, value: isActive)
    }
}

/// 实际的光环渲染 —— Apple Intelligence 风格的"液态玻璃"连续彩虹光环（v3 增强版）。
///
/// 关键思路：**保留连续的环**，不要让任何东西把环切成离散的色块。
/// 通过下面 5 个手段叠加出"液态玻璃 / 颠颠果冻"的感觉：
///
///   1. **4 层反方向旋转的彩虹环叠加** → 颜色在环上像漩涡一样搅动
///      - 外层柔光（特大模糊）顺时针 4.5s
///      - 中层主体（中模糊）逆时针 6.5s + .plusLighter 融合
///      - 内层高光（细描边）顺时针 2.8s
///      - **新增 内反光层**（极细 + .overlay）模拟玻璃内表面反射
///   2. **多频率呼吸**（周期更短，颠颠感更明显）
///      - lineWidth 范围更大：24~52pt（外）、12~26pt（中）、4~10pt（内）
///      - 整体 scale 1.0 ↔ 1.022（更明显的呼吸感）
///      - saturation 0.85 ↔ 1.15
///   3. **形状本身在液动**：cornerRadius 18~22pt 呼吸，让矩形圆角"涌动"
///   4. **角度速度 cos 调制** → 旋转忽快忽慢，不是匀速，更像液体被搅动
///   5. **hueRotation 微变** ±12° → 颜色相对位置在缓慢漂移，"莹润流动"感
///
///   全部 TimelineView(.animation) 驱动，60Hz+ 持续刷新
private struct AnimatedGlow: View {

    private var colors: [Color] { IntelligenceGlowView.appleAIColors }

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { context in
                let t = context.date.timeIntervalSinceReferenceDate

                // 三个错相的呼吸函数（0~1）—— 用于驱动各层呼吸
                let breath    = (sin(t * 2 * .pi / 1.8) + 1) / 2              // 1.8s 主呼吸（颠颠感）
                let breathAlt = (sin(t * 2 * .pi / 2.6 + 1.3) + 1) / 2        // 2.6s 错相
                let breathSlow = (sin(t * 2 * .pi / 5.0 + 0.7) + 1) / 2       // 5.0s 慢呼吸（驱动 hue / cornerRadius）

                // ── 各层 lineWidth 呼吸 —— 厚度脉动范围更大，颠颠更明显
                let outerWidth: CGFloat = 24 + 28 * CGFloat(breath)           // 24~52（原 30~44）
                let midWidth:   CGFloat = 12 + 14 * CGFloat(breathAlt)        // 12~26
                let innerWidth: CGFloat = 4  + 6  * CGFloat(breath)           // 4~10
                let reflectWidth: CGFloat = 2 + 2 * CGFloat(breathAlt)        // 2~4 极细内反光

                // ── 形状本身呼吸：圆角脉动让矩形涌动
                let outerCorner: CGFloat = 18 + 6 * CGFloat(breathSlow)       // 18~24
                let midCorner:   CGFloat = 16 + 4 * CGFloat(breath)           // 16~20
                let innerCorner: CGFloat = 14 + 4 * CGFloat(breathAlt)        // 14~18

                // ── 角度速度 cos 调制 —— 旋转忽快忽慢
                // 基础角度 + cos 项让瞬时角速度在 0.7x ~ 1.3x 间波动
                let outerAngle = t * 360 / 4.5 + 25 * sin(t * 2 * .pi / 3.2)
                let midAngle   = -t * 360 / 6.5 + 90 + 30 * sin(t * 2 * .pi / 2.8 + 1.0)
                let innerAngle = t * 360 / 2.8 + 200 + 18 * sin(t * 2 * .pi / 2.1)
                let reflectAngle = -t * 360 / 9.0 + 45

                // ── 整体呼吸
                let saturation: Double = 0.85 + 0.30 * breathAlt              // 0.85~1.15
                let scaleBreath: CGFloat = 1.0 + 0.022 * CGFloat(breath)      // 1.000~1.022
                let hueShift = Angle.degrees(12 * (breathSlow - 0.5) * 2)     // ±12° 颜色漂移

                ZStack {
                    // ── 层 1：外层柔光（大模糊氛围底）—— 顺时针 4.5s 一圈
                    AngularGradient(
                        gradient: Gradient(colors: colors),
                        center: .center,
                        angle: .degrees(outerAngle)
                    )
                    .mask(
                        RoundedRectangle(cornerRadius: outerCorner, style: .continuous)
                            .stroke(lineWidth: outerWidth)
                            .blur(radius: 36 + 16 * CGFloat(breathAlt))       // 36~52pt 模糊
                    )
                    .opacity(1.0)

                    // ── 层 2：中层主体（颜色搅动核心）—— 逆时针 6.5s 一圈
                    // 反方向 + 不同速度让颜色像漩涡里融合，而不是统一旋转
                    AngularGradient(
                        gradient: Gradient(colors: colors),
                        center: .center,
                        angle: .degrees(midAngle)
                    )
                    .mask(
                        RoundedRectangle(cornerRadius: midCorner, style: .continuous)
                            .stroke(lineWidth: midWidth)
                            .blur(radius: 14 + 6 * CGFloat(breath))           // 14~20pt
                    )
                    .blendMode(.plusLighter)
                    .opacity(0.92)

                    // ── 层 3：内层高光细描边（晶莹锐利边缘）—— 顺时针 2.8s 一圈
                    AngularGradient(
                        gradient: Gradient(colors: colors),
                        center: .center,
                        angle: .degrees(innerAngle)
                    )
                    .mask(
                        RoundedRectangle(cornerRadius: innerCorner, style: .continuous)
                            .stroke(lineWidth: innerWidth)
                            .blur(radius: 3 + 2 * CGFloat(breathAlt))
                    )
                    .blendMode(.plusLighter)
                    .opacity(0.95)

                    // ── 层 4：内反光（玻璃内表面反射）—— 极细，逆向慢转
                    // .overlay 混合模式让它跟下层颜色相互作用，模拟玻璃下的反光
                    AngularGradient(
                        gradient: Gradient(colors: colors),
                        center: .center,
                        angle: .degrees(reflectAngle)
                    )
                    .mask(
                        RoundedRectangle(cornerRadius: innerCorner - 2, style: .continuous)
                            .stroke(lineWidth: reflectWidth)
                            .blur(radius: 1.5)
                    )
                    .blendMode(.overlay)
                    .opacity(0.7)
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .hueRotation(hueShift)                                        // 颜色微漂移
                .saturation(saturation)
                .scaleEffect(scaleBreath)
                .compositingGroup()
            }
        }
    }
}

// 暴露给 AnimatedGlow 用
extension IntelligenceGlowView {
    static var appleAIColors: [Color] { colors }
}

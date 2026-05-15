import Foundation
import Carbon

/// 全局热键管理（Carbon Event Manager）。
/// 当前注册：
///   - Cmd+Shift+H → 切换聊天窗口（id=1，仅 down）
///   - Cmd+Shift+J → 截屏并附加到聊天（id=2，仅 down）
///   - Cmd+Shift+V → 按住说话（id=3，监听 down + up，实现 push-to-talk）
///   - Cmd+Shift+Space → Spotlight 风快问（id=4，仅 down）
final class GlobalHotkey {
    private var toggleHotKeyRef:  EventHotKeyRef?
    private var captureHotKeyRef: EventHotKeyRef?
    private var voiceHotKeyRef:   EventHotKeyRef?
    private var quickAskHotKeyRef: EventHotKeyRef?

    private nonisolated(unsafe) static var _toggleHandler:    (() -> Void)?
    private nonisolated(unsafe) static var _captureHandler:   (() -> Void)?
    private nonisolated(unsafe) static var _voiceDownHandler: (() -> Void)?
    private nonisolated(unsafe) static var _voiceUpHandler:   (() -> Void)?
    private nonisolated(unsafe) static var _quickAskHandler:  (() -> Void)?
    nonisolated(unsafe) static let shared = GlobalHotkey()

    private nonisolated(unsafe) static var handlerInstalled = false

    func register(
        toggle: @escaping () -> Void,
        capture: @escaping () -> Void,
        voiceDown: @escaping () -> Void,
        voiceUp: @escaping () -> Void,
        quickAsk: @escaping () -> Void
    ) {
        GlobalHotkey._toggleHandler    = toggle
        GlobalHotkey._captureHandler   = capture
        GlobalHotkey._voiceDownHandler = voiceDown
        GlobalHotkey._voiceUpHandler   = voiceUp
        GlobalHotkey._quickAskHandler  = quickAsk

        // 全局事件 handler 只装一次。监听 keyPressed + keyReleased 两种事件。
        if !GlobalHotkey.handlerInstalled {
            let specs: [EventTypeSpec] = [
                EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed)),
                EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyReleased))
            ]
            _ = specs.withUnsafeBufferPointer { buf in
                InstallEventHandler(GetApplicationEventTarget(), { (_, event, _) -> OSStatus in
                    var hk = EventHotKeyID()
                    let err = GetEventParameter(
                        event,
                        OSType(kEventParamDirectObject),
                        OSType(typeEventHotKeyID),
                        nil,
                        MemoryLayout<EventHotKeyID>.size,
                        nil,
                        &hk
                    )
                    if err == noErr {
                        let kind = GetEventKind(event)
                        DispatchQueue.main.async {
                            switch (hk.id, Int(kind)) {
                            case (1, kEventHotKeyPressed):
                                GlobalHotkey._toggleHandler?()
                            case (2, kEventHotKeyPressed):
                                GlobalHotkey._captureHandler?()
                            case (3, kEventHotKeyPressed):
                                GlobalHotkey._voiceDownHandler?()
                            case (3, kEventHotKeyReleased):
                                GlobalHotkey._voiceUpHandler?()
                            case (4, kEventHotKeyPressed):
                                GlobalHotkey._quickAskHandler?()
                            default: break
                            }
                        }
                    }
                    return noErr
                }, specs.count, buf.baseAddress, nil, nil)
            }
            GlobalHotkey.handlerInstalled = true
        }

        // 三个全局热键，注册失败时弹灵动岛通知告诉用户哪个被占用
        var failures: [String] = []

        toggleHotKeyRef = Self.tryRegister(
            keyCode: UInt32(kVK_ANSI_H),
            modifiers: UInt32(cmdKey | shiftKey),
            id: 1
        ) ?? {
            failures.append("⌘⇧H（呼出聊天）")
            return nil
        }()

        captureHotKeyRef = Self.tryRegister(
            keyCode: UInt32(kVK_ANSI_J),
            modifiers: UInt32(cmdKey | shiftKey),
            id: 2
        ) ?? {
            failures.append("⌘⇧J（截屏）")
            return nil
        }()

        voiceHotKeyRef = Self.tryRegister(
            keyCode: UInt32(kVK_ANSI_V),
            modifiers: UInt32(cmdKey | shiftKey),
            id: 3
        ) ?? {
            failures.append("⌘⇧V（语音）")
            return nil
        }()

        // ⌘⇧Space —— Spotlight 风快问（kVK_Space = 49）
        quickAskHotKeyRef = Self.tryRegister(
            keyCode: UInt32(kVK_Space),
            modifiers: UInt32(cmdKey | shiftKey),
            id: 4
        ) ?? {
            failures.append("⌘⇧Space（快问）")
            return nil
        }()

        if !failures.isEmpty {
            // 通过截图通知通道弹灵动岛提示（这条通道短暂展开胶囊显示文字）
            let msg = "⚠️ 这些热键被别的 app 占用：" + failures.joined(separator: "、")
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .init("HermesPetScreenshotAdded"),
                    object: nil,
                    userInfo: ["text": msg, "count": 0]
                )
            }
        }
    }

    /// 尝试注册一个 Carbon 全局热键；成功返回 ref，失败返回 nil（被占用 / 系统限制等）
    private static func tryRegister(keyCode: UInt32, modifiers: UInt32, id: UInt32) -> EventHotKeyRef? {
        let hkid = EventHotKeyID(signature: 0x484D4550, id: id)
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hkid,
            GetApplicationEventTarget(),
            0,
            &ref
        )
        return status == noErr ? ref : nil
    }

    deinit {
        if let ref = toggleHotKeyRef   { UnregisterEventHotKey(ref) }
        if let ref = captureHotKeyRef  { UnregisterEventHotKey(ref) }
        if let ref = voiceHotKeyRef    { UnregisterEventHotKey(ref) }
        if let ref = quickAskHotKeyRef { UnregisterEventHotKey(ref) }
    }
}

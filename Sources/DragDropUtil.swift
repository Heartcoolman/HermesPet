import AppKit
import UniformTypeIdentifiers

/// 拖入文件的统一处理工具。
/// 全聊天窗口的 onDrop 都走这里：
/// - 图片（PNG/JPG/HEIC 等）→ 调 onImage(Data)
/// - 其余文件（PDF / txt / md / 代码 / 任意类型）→ 调 onDocument(URL)，**只回传路径**
///
/// 文档不再读全文 —— Claude/Codex 模式下让 AI 用自己的 Read 工具按路径访问，速度更快、不占 context。
/// Hermes 模式（HTTP API）无法访问本地文件，由 ViewModel 拦截后弹错误提示。
enum DragDropUtil {

    /// SwiftUI .onDrop(of:) 用这个 UTType 列表 —— 故意只用最通用的两个，
    /// 加更多反而会让 macOS 拒绝某些拖入源（mail 附件、Finder 等）
    static let acceptedUTTypes: [UTType] = [.fileURL, .image]

    /// onDrop perform 直接调这个。返回 true 表示有 provider 被处理。
    @MainActor
    static func handleProviders(
        _ providers: [NSItemProvider],
        onImage: @escaping @MainActor (Data) -> Void,
        onDocument: @escaping @MainActor (URL) -> Void
    ) -> Bool {
        var handled = false
        for provider in providers {
            // 直接是 NSImage（截图工具、浏览器拖图 等）—— 只能拿到 Data，没本地路径
            if provider.canLoadObject(ofClass: NSImage.self) {
                handled = true
                _ = provider.loadObject(ofClass: NSImage.self) { item, _ in
                    if let img = item as? NSImage, let png = pngData(from: img) {
                        DispatchQueue.main.async { onImage(png) }
                    }
                }
                continue
            }
            // 文件 URL（Finder 拖文件）
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                handled = true
                _ = provider.loadDataRepresentation(forTypeIdentifier: UTType.fileURL.identifier) { data, _ in
                    guard let data = data,
                          let url = URL(dataRepresentation: data, relativeTo: nil)
                    else { return }
                    processFile(url, onImage: { png in
                        DispatchQueue.main.async { onImage(png) }
                    }, onDocument: { docURL in
                        DispatchQueue.main.async { onDocument(docURL) }
                    })
                }
            }
        }
        return handled
    }

    /// 根据 URL 扩展名分流：
    /// - 图片扩展名 → 读 PNG Data（图片必须传 base64/Data，没法走路径）
    /// - 其他所有文件 → 只回传 URL，让 AI 自己用 Read 工具去读
    nonisolated static func processFile(
        _ url: URL,
        onImage: @escaping @Sendable (Data) -> Void,
        onDocument: @escaping @Sendable (URL) -> Void
    ) {
        let ext = url.pathExtension.lowercased()

        let imageExts: Set<String> = ["png", "jpg", "jpeg", "heic", "webp", "gif", "bmp", "tiff"]
        if imageExts.contains(ext), let img = NSImage(contentsOf: url), let png = pngData(from: img) {
            onImage(png)
            return
        }

        // 非图片：统一只回传路径，不再读内容
        onDocument(url)
    }

    nonisolated static func pngData(from image: NSImage) -> Data? {
        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff) else { return nil }
        return bitmap.representation(using: .png, properties: [:])
    }
}

import SwiftUI
import Combine

final class AppSettings: ObservableObject {
    // MARK: - 翻译
    @Published var apiKey: String { didSet { save(apiKey, "cleanx.apiKey") } }
    @Published var targetLanguage: String { didSet { save(targetLanguage, "cleanx.targetLanguage") } }

    // MARK: - 隐藏 / 过滤
    @Published var hideAds: Bool { didSet { save(hideAds, "cleanx.hideAds") } }
    @Published var hideSidebars: Bool { didSet { save(hideSidebars, "cleanx.hideSidebars") } }
    @Published var hideWhoToFollow: Bool { didSet { save(hideWhoToFollow, "cleanx.hideWhoToFollow") } }
    @Published var hidePremium: Bool { didSet { save(hidePremium, "cleanx.hidePremium") } }
    @Published var hideVerified: Bool { didSet { save(hideVerified, "cleanx.hideVerified") } }
    @Published var hideViewCount: Bool { didSet { save(hideViewCount, "cleanx.hideViewCount") } }
    @Published var hideBookmark: Bool { didSet { save(hideBookmark, "cleanx.hideBookmark") } }
    @Published var hideSpaces: Bool { didSet { save(hideSpaces, "cleanx.hideSpaces") } }

    // MARK: - 关键字
    @Published var keywords: [String] { didSet { save(keywords, "cleanx.keywords") } }

    // MARK: - 时间线
    @Published var alwaysFollowing: Bool { didSet { save(alwaysFollowing, "cleanx.alwaysFollowing") } }

    // MARK: - 外观
    @Published var theme: Theme { didSet { save(theme.rawValue, "cleanx.theme") } }
    @Published var customFont: FontStyle { didSet { save(customFont.rawValue, "cleanx.customFont") } }
    @Published var accentColor: AccentColor { didSet { save(accentColor.rawValue, "cleanx.accentColor") } }

    enum Theme: String, CaseIterable, Identifiable {
        case system = "跟随系统"
        case dark = "深色"
        case light = "浅色"
        case dim = "暗蓝"
        var id: String { rawValue }
    }

    enum FontStyle: String, CaseIterable, Identifiable {
        case system = "系统默认"
        case rounded = "圆体"
        case mono = "等宽"
        case serif = "衬线"
        var id: String { rawValue }
        var css: String {
            switch self {
            case .system: return "-apple-system, system-ui, sans-serif"
            case .rounded: return "-apple-system-rounded, ui-rounded, sans-serif"
            case .mono: return "ui-monospace, SFMono-Regular, Menlo, monospace"
            case .serif: return "Georgia, 'Times New Roman', serif"
            }
        }
    }

    enum AccentColor: String, CaseIterable, Identifiable {
        case blue = "蓝 #1d9bf0"
        case purple = "紫 #8b5cf6"
        case green = "绿 #00ba7c"
        case red = "红 #f91880"
        case orange = "橙 #ff7a00"
        case pink = "粉 #e91e63"
        var id: String { rawValue }
        var hex: String {
            switch self {
            case .blue: return "#1d9bf0"
            case .purple: return "#8b5cf6"
            case .green: return "#00ba7c"
            case .red: return "#f91880"
            case .orange: return "#ff7a00"
            case .pink: return "#e91e63"
            }
        }
    }

    init() {
        let d = UserDefaults.standard
        apiKey = d.string(forKey: "cleanx.apiKey") ?? ""
        targetLanguage = d.string(forKey: "cleanx.targetLanguage") ?? "简体中文"
        hideAds = d.object(forKey: "cleanx.hideAds") as? Bool ?? true
        hideSidebars = d.object(forKey: "cleanx.hideSidebars") as? Bool ?? true
        hideWhoToFollow = d.object(forKey: "cleanx.hideWhoToFollow") as? Bool ?? true
        hidePremium = d.object(forKey: "cleanx.hidePremium") as? Bool ?? true
        hideVerified = d.object(forKey: "cleanx.hideVerified") as? Bool ?? false
        hideViewCount = d.object(forKey: "cleanx.hideViewCount") as? Bool ?? false
        hideBookmark = d.object(forKey: "cleanx.hideBookmark") as? Bool ?? false
        hideSpaces = d.object(forKey: "cleanx.hideSpaces") as? Bool ?? false
        keywords = d.stringArray(forKey: "cleanx.keywords") ?? []
        alwaysFollowing = d.object(forKey: "cleanx.alwaysFollowing") as? Bool ?? false
        theme = Theme(rawValue: d.string(forKey: "cleanx.theme") ?? "") ?? .system
        customFont = FontStyle(rawValue: d.string(forKey: "cleanx.customFont") ?? "") ?? .system
        accentColor = AccentColor(rawValue: d.string(forKey: "cleanx.accentColor") ?? "") ?? .blue
    }

    private func save(_ value: Any, _ key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }

    /// 生成注入到网页里的设置对象（JS 片段）
    func settingsPayload() -> String {
        let cleaned = keywords
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let kwJSON: String
        if let data = try? JSONSerialization.data(withJSONObject: cleaned),
           let s = String(data: data, encoding: .utf8) {
            kwJSON = s
        } else {
            kwJSON = "[]"
        }

        var lang = targetLanguage
        lang = lang.replacingOccurrences(of: "\\", with: "\\\\")
        lang = lang.replacingOccurrences(of: "\"", with: "\\\"")
        lang = lang.replacingOccurrences(of: "\n", with: "\\n")

        let fontCss = customFont.css.replacingOccurrences(of: "\"", with: "\\\"")

        return """
        window.__CLEANX__ = {
          keywords: \(kwJSON),
          lang: "\(lang)",
          hideAds: \(hideAds),
          hideSidebars: \(hideSidebars),
          hideWhoToFollow: \(hideWhoToFollow),
          hidePremium: \(hidePremium),
          hideVerified: \(hideVerified),
          hideViewCount: \(hideViewCount),
          hideBookmark: \(hideBookmark),
          hideSpaces: \(hideSpaces),
          alwaysFollowing: \(alwaysFollowing),
          font: "\(fontCss)",
          accent: "\(accentColor.hex)",
          theme: \(themeColors)
        };
        """
    }

    private var themeColors: String {
        switch theme {
        case .dark:   return "{ background: '#000000', text: '#e7e9ea', accent: '#1d9bf0' }"
        case .light:  return "{ background: '#ffffff', text: '#0f1419', accent: '#1d9bf0' }"
        case .dim:    return "{ background: '#15202b', text: '#f7f9f9', accent: '#1d9bf0' }"
        case .system: return "null"
        }
    }
}

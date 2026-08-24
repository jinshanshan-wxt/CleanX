import SwiftUI
import Combine

final class AppSettings: ObservableObject {
    @Published var apiKey: String {
        didSet { UserDefaults.standard.set(apiKey, forKey: "cleanx.apiKey") }
    }
    @Published var targetLanguage: String {
        didSet { UserDefaults.standard.set(targetLanguage, forKey: "cleanx.targetLanguage") }
    }
    @Published var keywords: [String] {
        didSet { UserDefaults.standard.set(keywords, forKey: "cleanx.keywords") }
    }
    @Published var hideAds: Bool {
        didSet { UserDefaults.standard.set(hideAds, forKey: "cleanx.hideAds") }
    }
    @Published var hideSidebars: Bool {
        didSet { UserDefaults.standard.set(hideSidebars, forKey: "cleanx.hideSidebars") }
    }
    @Published var theme: Theme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: "cleanx.theme") }
    }

    enum Theme: String, CaseIterable, Identifiable {
        case system = "跟随系统"
        case dark = "深色"
        case light = "浅色"
        case dim = "暗蓝"
        var id: String { rawValue }
    }

    init() {
        let d = UserDefaults.standard
        apiKey = d.string(forKey: "cleanx.apiKey") ?? ""
        targetLanguage = d.string(forKey: "cleanx.targetLanguage") ?? "简体中文"
        keywords = d.stringArray(forKey: "cleanx.keywords") ?? []
        hideAds = d.object(forKey: "cleanx.hideAds") as? Bool ?? true
        hideSidebars = d.object(forKey: "cleanx.hideSidebars") as? Bool ?? true
        theme = Theme(rawValue: d.string(forKey: "cleanx.theme") ?? "") ?? .system
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

        return """
        window.__CLEANX__ = {
          keywords: \(kwJSON),
          lang: "\(lang)",
          hideAds: \(hideAds),
          hideSidebars: \(hideSidebars),
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

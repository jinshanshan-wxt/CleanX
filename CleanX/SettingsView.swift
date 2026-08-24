import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @State private var newKeyword = ""
    @State private var selectedIcon = "default"

    var body: some View {
        NavigationStack {
            Form {
                Section("翻译（DeepSeek）") {
                    SecureField("API Key", text: $settings.apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("目标语言", text: $settings.targetLanguage)
                    Text("推文上的“翻译”按钮会调用 DeepSeek，使用你自己的 API Key 计费。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("时间线") {
                    Toggle("默认打开「关注」页（实验性）", isOn: $settings.alwaysFollowing)
                }

                Section("隐藏 / 过滤") {
                    Toggle("广告 / 推广", isOn: $settings.hideAds)
                    Toggle("推荐关注 (Who to follow)", isOn: $settings.hideWhoToFollow)
                    Toggle("Premium 推广", isOn: $settings.hidePremium)
                    Toggle("认证蓝标", isOn: $settings.hideVerified)
                    Toggle("浏览量", isOn: $settings.hideViewCount)
                    Toggle("收藏按钮", isOn: $settings.hideBookmark)
                    Toggle("Spaces 语音", isOn: $settings.hideSpaces)
                    Toggle("右侧边栏", isOn: $settings.hideSidebars)
                }

                Section("关键字屏蔽") {
                    ForEach(settings.keywords, id: \.self) { kw in
                        Text(kw)
                    }
                    .onDelete { settings.keywords.remove(atOffsets: $0) }

                    HStack {
                        TextField("添加关键字（支持正则）", text: $newKeyword)
                        Button("添加") {
                            let k = newKeyword.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !k.isEmpty {
                                settings.keywords.append(k)
                                newKeyword = ""
                            }
                        }
                        .disabled(newKeyword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }

                Section("外观") {
                    Picker("主题", selection: $settings.theme) {
                        ForEach(AppSettings.Theme.allCases) { t in Text(t.rawValue).tag(t) }
                    }
                    Picker("字体", selection: $settings.customFont) {
                        ForEach(AppSettings.FontStyle.allCases) { f in Text(f.rawValue).tag(f) }
                    }
                    Picker("强调色", selection: $settings.accentColor) {
                        ForEach(AppSettings.AccentColor.allCases) { c in Text(c.rawValue).tag(c) }
                    }
                }

                Section("App 图标") {
                    Picker("图标", selection: $selectedIcon) {
                        ForEach(AppIcons.all) { opt in
                            Text(opt.label).tag(opt.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedIcon) { _, newValue in
                        if let opt = AppIcons.all.first(where: { $0.id == newValue }) {
                            AppIcons.apply(opt)
                        }
                    }
                    Text("切换后系统会弹一次确认，图标立即生效。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button("保存并应用") { dismiss() }
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
            .onAppear {
                selectedIcon = UIApplication.shared.alternateIconName ?? "default"
            }
        }
    }
}

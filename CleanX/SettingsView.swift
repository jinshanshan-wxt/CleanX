import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @State private var newKeyword = ""

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

                Section("过滤") {
                    Toggle("隐藏广告 / 推广", isOn: $settings.hideAds)
                    Toggle("隐藏侧边栏推荐", isOn: $settings.hideSidebars)
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
                        ForEach(AppSettings.Theme.allCases) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
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
        }
    }
}

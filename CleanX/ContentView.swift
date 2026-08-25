import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var showSettings = false
    @State private var mode: Mode = .native

    enum Mode: String, CaseIterable, Identifiable {
        case native = "原生"
        case web = "网页"
        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                WebContainer(settings: settings)
                    .opacity(mode == .web ? 1 : 0)
                    .allowsHitTesting(mode == .web)
                if mode == .native {
                    NativeTimelineView(onOpen: { url in openInWeb(url) })
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if settings.showWebMode {
                    ToolbarItem(placement: .principal) {
                        Picker("模式", selection: $mode) {
                            ForEach(Mode.allCases) { m in Text(m.rawValue).tag(m) }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 140)
                    }
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    if mode == .web {
                        Button { nav("https://x.com/home") } label: { Image(systemName: "house") }
                        Button { nav("https://x.com/explore") } label: { Image(systemName: "magnifyingglass") }
                        Button { nav("https://x.com/notifications") } label: { Image(systemName: "bell") }
                        Button { nav("https://x.com/messages") } label: { Image(systemName: "envelope") }
                        Spacer()
                    }
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView().environmentObject(settings)
            }
            .onChange(of: settings.showWebMode) { _, on in
                if !on { mode = .native }
            }
        }
    }

    private func nav(_ urlString: String) {
        mode = .web
        WebContainer.sharedWebView?.load(URLRequest(url: URL(string: urlString)!))
    }

    private func openInWeb(_ urlString: String) {
        guard settings.showWebMode else { return }   // 网页模式未开启，不跳转
        mode = .web
        if let u = URL(string: urlString) {
            WebContainer.sharedWebView?.load(URLRequest(url: u))
        }
    }
}

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var showSettings = false
    @State private var mode: Mode = .web

    enum Mode: String, CaseIterable, Identifiable {
        case web = "网页"
        case native = "原生"
        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                WebContainer(settings: settings)
                    .opacity(mode == .web ? 1 : 0)
                    .allowsHitTesting(mode == .web)
                if mode == .native {
                    NativeTimelineView()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("模式", selection: $mode) {
                        ForEach(Mode.allCases) { m in Text(m.rawValue).tag(m) }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 140)
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    Button { nav("https://x.com/home") } label: { Image(systemName: "house") }
                    Button { nav("https://x.com/explore") } label: { Image(systemName: "magnifyingglass") }
                    Button { nav("https://x.com/notifications") } label: { Image(systemName: "bell") }
                    Button { nav("https://x.com/messages") } label: { Image(systemName: "envelope") }
                    Spacer()
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView().environmentObject(settings)
            }
        }
    }

    private func nav(_ urlString: String) {
        mode = .web
        WebContainer.sharedWebView?.load(URLRequest(url: URL(string: urlString)!))
    }
}

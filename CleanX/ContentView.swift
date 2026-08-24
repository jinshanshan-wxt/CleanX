import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            WebContainer(settings: settings)
                .toolbar {
                    ToolbarItemGroup(placement: .bottomBar) {
                        Button { WebContainer.sharedWebView?.goBack() } label: { Image(systemName: "chevron.left") }
                        Button { WebContainer.sharedWebView?.goForward() } label: { Image(systemName: "chevron.right") }
                        Spacer()
                        Button { WebContainer.sharedWebView?.reload() } label: { Image(systemName: "arrow.clockwise") }
                        Spacer()
                        Button { WebContainer.sharedWebView?.load(URLRequest(url: URL(string: "https://x.com/home")!)) } label: { Image(systemName: "house") }
                        Button { showSettings = true } label: { Image(systemName: "gearshape") }
                    }
                }
                .sheet(isPresented: $showSettings) {
                    SettingsView().environmentObject(settings)
                }
        }
    }
}

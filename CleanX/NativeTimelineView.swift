import SwiftUI
import WebKit

struct NativeTimelineView: View {
    @State private var tweets: [Tweet] = []
    @State private var message: String?

    var body: some View {
        VStack {
            if let message {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
            }
            if tweets.isEmpty && message == nil {
                Spacer()
                ProgressView("抓取时间线中…")
                Spacer()
            } else {
                List(tweets) { t in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(t.authorName).font(.subheadline).bold()
                            Text(t.authorHandle).font(.caption).foregroundStyle(.secondary)
                            Spacer()
                            if let ts = t.timestamp {
                                Text(ts).font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                        Text(t.text).font(.body)
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.plain)
            }
        }
        .onAppear { scrape() }
        .refreshable { scrape() }
    }

    private func scrape() {
        guard let wv = WebContainer.sharedWebView else {
            message = "网页未加载"
            return
        }
        wv.evaluateJavaScript("window.__CLEANX_scrape && window.__CLEANX_scrape()") { result, error in
            if let error {
                DispatchQueue.main.async { self.message = error.localizedDescription }
                return
            }
            guard let json = result as? String,
                  let data = json.data(using: .utf8),
                  let arr = try? JSONDecoder().decode([Tweet].self, from: data) else {
                DispatchQueue.main.async { self.message = "解析失败" }
                return
            }
            DispatchQueue.main.async {
                self.tweets = arr
                self.message = arr.isEmpty ? "没抓到推文（可能未登录或网页未加载完）" : nil
            }
        }
    }
}

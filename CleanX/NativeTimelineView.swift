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
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 14) {
                        ForEach(tweets) { t in
                            TweetRow(tweet: t)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                }
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

// 单条推文行
struct TweetRow: View {
    let tweet: Tweet

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            RemoteImage(url: tweet.avatarURL)
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(tweet.authorName).font(.subheadline).bold()
                    Text(tweet.authorHandle).font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Text(relativeTime(tweet.timestamp)).font(.caption2).foregroundStyle(.secondary)
                }
                Text(tweet.text).font(.body)
                if !tweet.mediaURLs.isEmpty {
                    MediaGrid(urls: tweet.mediaURLs)
                        .padding(.top, 2)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// 远程图片
struct RemoteImage: View {
    let url: String?

    var body: some View {
        AsyncImage(url: url.flatMap { URL(string: $0) }) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            default:
                Color.gray.opacity(0.2)
            }
        }
    }
}

// 图片网格（1-4 张）
struct MediaGrid: View {
    let urls: [String]
    private let columns = [GridItem(.flexible(), spacing: 4), GridItem(.flexible(), spacing: 4)]

    var body: some View {
        if urls.count == 1 {
            RemoteImage(url: urls.first)
                .frame(maxWidth: 260, maxHeight: 260)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        } else {
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(urls.prefix(4).enumerated()), id: \.offset) { _, u in
                    RemoteImage(url: u)
                        .aspectRatio(1, contentMode: .fill)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
}

// 相对时间
func relativeTime(_ iso: String?) -> String {
    guard let iso = iso else { return "" }
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    var date = f.date(from: iso)
    if date == nil {
        f.formatOptions = [.withInternetDateTime]
        date = f.date(from: iso)
    }
    guard let d = date else { return iso }
    let delta = Date().timeIntervalSince(d)
    if delta < 60 { return "刚刚" }
    if delta < 3600 { return "\(Int(delta / 60))分钟前" }
    if delta < 86400 { return "\(Int(delta / 3600))小时前" }
    if delta < 86400 * 7 { return "\(Int(delta / 86400))天前" }
    let df = DateFormatter()
    df.dateFormat = "MM-dd"
    return df.string(from: d)
}

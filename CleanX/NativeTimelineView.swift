import SwiftUI
import WebKit

struct NativeTimelineView: View {
    @State private var tweets: [Tweet] = []
    @State private var message: String?
    @State private var isLoadingMore = false
    @State private var noMore = false

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
                            TweetRow(tweet: t) { tweet, action in
                                performAction(tweet, action)
                            }
                        }
                        if isLoadingMore {
                            HStack { Spacer(); ProgressView(); Spacer() }
                                .padding(.vertical, 8)
                        } else if noMore {
                            Text("没有更多了")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                        Color.clear
                            .frame(height: 20)
                            .onAppear { loadMore() }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                }
            }
        }
        .onAppear { refresh() }
        .refreshable { refresh() }
    }

    private func refresh() {
        noMore = false
        scrape(append: false)
    }

    private func loadMore() {
        guard !isLoadingMore, !noMore, !tweets.isEmpty else { return }
        isLoadingMore = true
        WebContainer.sharedWebView?.evaluateJavaScript("window.__CLEANX_scrollToBottom && window.__CLEANX_scrollToBottom()") { _, _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                self.scrape(append: true)
            }
        }
    }

    private func performAction(_ tweet: Tweet, _ action: String) {
        let js = "window.__CLEANX_act && window.__CLEANX_act('\(tweet.id)', '\(action)')"
        WebContainer.sharedWebView?.evaluateJavaScript(js, completionHandler: nil)
    }

    private func scrape(append: Bool) {
        guard let wv = WebContainer.sharedWebView else {
            message = "网页未加载"
            isLoadingMore = false
            return
        }
        wv.evaluateJavaScript("window.__CLEANX_scrape && window.__CLEANX_scrape()") { result, error in
            if let error {
                DispatchQueue.main.async { self.message = error.localizedDescription; self.isLoadingMore = false }
                return
            }
            guard let json = result as? String,
                  let data = json.data(using: .utf8),
                  let arr = try? JSONDecoder().decode([Tweet].self, from: data) else {
                DispatchQueue.main.async { self.message = "解析失败"; self.isLoadingMore = false }
                return
            }
            DispatchQueue.main.async {
                self.isLoadingMore = false
                if append {
                    let seen = Set(self.tweets.map { $0.id })
                    let added = arr.filter { !seen.contains($0.id) }
                    if added.isEmpty {
                        self.noMore = true
                    } else {
                        self.tweets.append(contentsOf: added)
                    }
                } else {
                    self.tweets = arr
                    self.message = arr.isEmpty ? "没抓到推文（可能未登录或网页未加载完）" : nil
                }
            }
        }
    }
}

// 单条推文行
struct TweetRow: View {
    let tweet: Tweet
    let onAction: (Tweet, String) -> Void
    @State private var liked = false
    @State private var reposted = false

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
                actionBar
            }
        }
        .padding(.vertical, 4)
    }

    private var actionBar: some View {
        HStack(spacing: 22) {
            Button { onAction(tweet, "reply") } label: {
                HStack(spacing: 3) {
                    Image(systemName: "bubble.left")
                    if let c = tweet.replyCount, !c.isEmpty { Text(c) }
                }
            }
            Button {
                reposted.toggle()
                onAction(tweet, "repost")
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: "repeat")
                    if let c = tweet.repostCount, !c.isEmpty { Text(c) }
                }
            }
            .foregroundStyle(reposted ? .green : .secondary)
            Button {
                liked.toggle()
                onAction(tweet, "like")
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: liked ? "heart.fill" : "heart")
                    if let c = tweet.likeCount, !c.isEmpty { Text(c) }
                }
            }
            .foregroundStyle(liked ? .red : .secondary)
            if let c = tweet.viewCount, !c.isEmpty {
                HStack(spacing: 3) {
                    Image(systemName: "eye")
                    Text(c)
                }
            }
            Spacer(minLength: 0)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.top, 4)
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

import Foundation
import WebKit

struct XAuthTokens {
    let authToken: String
    let ct0: String
}

/// X 内部 GraphQL 接口客户端（脚手架）
/// 说明：X 的 query id / 请求体经常变，且需真实登录态。当前只搭好"取 cookie + 发请求"的骨架，
/// 真正打通前需要：1) 用真实登录态抓包拿到 HomeLatestTimeline 的 query id；2) 补全 variables/features。
final class TwitterAPIClient {
    private static let graphQLBase = "https://x.com/i/api/graphql"
    private static let homeTimelineQueryID = "TODO_QUERY_ID"          // TODO: 抓包获取
    private static let homeTimelineQueryName = "HomeLatestTimeline"
    // X 网页公开的 guest Bearer Token
    private static let guestBearer = "AAAAAAAAAAAAAAAAAAAAANRILgAAAAAAnNwIzUejRCOuH5E6I8xnZz4puTs%3D1Zv7ttfk8LF81IUq16cHjhLTvJu4FA33AGWWjCpTnA"

    /// 从登录过的 WKWebView 里取 auth_token / ct0
    static func extractTokens(from webView: WKWebView, completion: @escaping (XAuthTokens?) -> Void) {
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            var auth: String?
            var ct0: String?
            for c in cookies {
                if c.domain.contains("x.com") || c.domain.contains("twitter.com") {
                    if c.name == "auth_token" { auth = c.value }
                    if c.name == "ct0" { ct0 = c.value }
                }
            }
            if let a = auth, let c = ct0 {
                completion(XAuthTokens(authToken: a, ct0: c))
            } else {
                completion(nil)
            }
        }
    }

    /// 拉取首页时间线（脚手架：填好 queryID 与请求体后即可用）
    static func fetchHomeTimeline(tokens: XAuthTokens, completion: @escaping (Result<Data, Error>) -> Void) {
        let url = URL(string: "\(graphQLBase)/\(homeTimelineQueryID)/\(homeTimelineQueryName)")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(guestBearer)", forHTTPHeaderField: "Authorization")
        req.setValue(tokens.ct0, forHTTPHeaderField: "x-csrf-token")
        req.setValue("auth_token=\(tokens.authToken); ct0=\(tokens.ct0)", forHTTPHeaderField: "Cookie")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // TODO: 下面 variables/features/fieldToggles 需要抓包补全
        let body: [String: Any] = [
            "variables": [
                "count": 20,
                "includePromotedContent": false
            ],
            "features": [:],
            "fieldToggles": [:]
        ]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: req) { data, _, error in
            if let error { completion(.failure(error)); return }
            guard let data = data else {
                completion(.failure(NSError(domain: "TwitterAPIClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "无数据"])))
                return
            }
            completion(.success(data))
        }.resume()
    }
}

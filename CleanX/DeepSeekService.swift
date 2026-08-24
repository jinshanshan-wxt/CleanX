import Foundation

struct DeepSeekService {
    struct TranslationError: LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    /// 调用 DeepSeek 的 OpenAI 兼容接口翻译一段文本
    static func translate(text: String,
                          apiKey: String,
                          targetLanguage: String,
                          completion: @escaping (Result<String, Error>) -> Void) {
        guard !apiKey.isEmpty else {
            completion(.failure(TranslationError(message: "未配置 DeepSeek API Key")))
            return
        }

        let url = URL(string: "https://api.deepseek.com/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let system = "You are a professional translator. Translate the user's text into \(targetLanguage). Output only the translation, without any explanations, quotes, or extra text."
        let body: [String: Any] = [
            "model": "deepseek-chat",
            "messages": [
                ["role": "system", "content": system],
                ["role": "user", "content": text]
            ],
            "temperature": 0.3,
            "stream": false
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let message = choices.first?["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                let errObj = (try? JSONSerialization.jsonObject(with: data ?? Data())) as? [String: Any]
                let errMsg = (errObj?["error"] as? [String: Any])?["message"] as? String
                completion(.failure(TranslationError(message: errMsg ?? "翻译失败")))
                return
            }
            completion(.success(content.trimmingCharacters(in: .whitespacesAndNewlines)))
        }.resume()
    }
}

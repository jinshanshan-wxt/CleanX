import Foundation

enum InjectionScripts {
    static var mainJS: String? {
        guard let url = Bundle.main.url(forResource: "inject", withExtension: "js") else { return nil }
        return try? String(contentsOf: url, encoding: .utf8)
    }

    static var mainCSS: String? {
        guard let url = Bundle.main.url(forResource: "inject", withExtension: "css") else { return nil }
        return try? String(contentsOf: url, encoding: .utf8)
    }

    /// 把任意字符串转成能安全放进“双引号 JS 字符串字面量”的形式
    static func jsStringLiteral(_ s: String) -> String {
        var out = ""
        for ch in s {
            switch ch {
            case "\\": out += "\\\\"
            case "\"": out += "\\\""
            case "\n": out += "\\n"
            case "\r": out += "\\r"
            case "\t": out += "\\t"
            default: out.append(ch)
            }
        }
        return out
            .replacingOccurrences(of: "\u{2028}", with: "\\u2028")
            .replacingOccurrences(of: "\u{2029}", with: "\\u2029")
    }
}

import Foundation

struct Tweet: Identifiable, Decodable {
    let id: String
    let text: String
    let authorName: String
    let authorHandle: String
    let avatarURL: String?
    let timestamp: String?
}

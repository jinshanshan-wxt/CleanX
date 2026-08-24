import Foundation

struct Tweet: Identifiable, Decodable {
    let id: String
    let text: String
    let authorName: String
    let authorHandle: String
    let avatarURL: String?
    let timestamp: String?
    let mediaURLs: [String]
    let replyCount: String?
    let repostCount: String?
    let likeCount: String?
    let viewCount: String?
    let hasVideo: Bool
    let videoThumbURL: String?
    let statusURL: String?
}

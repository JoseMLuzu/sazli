import Foundation

enum RecipeCategory: String, CaseIterable, Identifiable, Sendable {
    case breakfast, lunch, dinner, dessert, other

    var id: String { rawValue }
    var title: String {
        switch self {
        case .breakfast: "Breakfast"
        case .lunch: "Lunch"
        case .dinner: "Dinner"
        case .dessert: "Dessert"
        case .other: "Other"
        }
    }

    var symbol: String {
        switch self {
        case .breakfast: "sunrise"
        case .lunch: "sun.max"
        case .dinner: "moon"
        case .dessert: "birthday.cake"
        case .other: "fork.knife"
        }
    }
}

enum SourcePlatform: String, CaseIterable, Identifiable, Sendable {
    case chatGPT, youtube, tiktok, facebook, web, manual

    var id: String { rawValue }
    var title: String {
        switch self {
        case .chatGPT: "ChatGPT"
        case .youtube: "YouTube"
        case .tiktok: "TikTok"
        case .facebook: "Facebook"
        case .web: "Web"
        case .manual: "Manual"
        }
    }
}

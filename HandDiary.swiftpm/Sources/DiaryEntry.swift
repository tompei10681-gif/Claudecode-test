import Foundation

struct DiaryEntry: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var date: Date
    var title: String
    var typedText: String
    var mood: Mood
    var weather: Weather
    var tags: [String]
    var drawingData: Data?
    var pageBackground: PageBackground
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var formattedDate: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "yyyy年M月d日（E）"
        return f.string(from: date)
    }

    var shortDate: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "M/d"
        return f.string(from: date)
    }

    enum Mood: String, Codable, CaseIterable {
        case great, good, neutral, bad, terrible

        var emoji: String {
            switch self {
            case .great:   return "😄"
            case .good:    return "🙂"
            case .neutral: return "😐"
            case .bad:     return "😔"
            case .terrible:return "😢"
            }
        }
        var label: String {
            switch self {
            case .great:   return "最高"
            case .good:    return "良い"
            case .neutral: return "普通"
            case .bad:     return "悪い"
            case .terrible:return "最悪"
            }
        }
    }

    enum Weather: String, Codable, CaseIterable {
        case sunny, cloudy, rainy, snowy, stormy, windy

        var icon: String {
            switch self {
            case .sunny:  return "sun.max.fill"
            case .cloudy: return "cloud.fill"
            case .rainy:  return "cloud.rain.fill"
            case .snowy:  return "snowflake"
            case .stormy: return "cloud.bolt.fill"
            case .windy:  return "wind"
            }
        }
        var label: String {
            switch self {
            case .sunny:  return "晴れ"
            case .cloudy: return "曇り"
            case .rainy:  return "雨"
            case .snowy:  return "雪"
            case .stormy: return "嵐"
            case .windy:  return "風"
            }
        }
    }

    enum PageBackground: String, Codable, CaseIterable {
        case plain, ruled, grid, dotted

        var label: String {
            switch self {
            case .plain:  return "白紙"
            case .ruled:  return "横罫線"
            case .grid:   return "方眼"
            case .dotted: return "ドット"
            }
        }
        var icon: String {
            switch self {
            case .plain:  return "square"
            case .ruled:  return "line.3.horizontal"
            case .grid:   return "grid"
            case .dotted: return "circle.grid.3x3"
            }
        }
    }

    static func new(for date: Date) -> DiaryEntry {
        DiaryEntry(date: date, title: "", typedText: "",
                   mood: .good, weather: .sunny,
                   tags: [], drawingData: nil, pageBackground: .ruled)
    }
}

import SwiftUI

enum AppPalette {
    case mint
    case blue
    case coral
    case violet
    case amber
    case sky

    var colors: [Color] {
        switch self {
        case .mint:
            [Color(red: 0.08, green: 0.53, blue: 0.45), Color(red: 0.55, green: 0.91, blue: 0.75)]
        case .blue:
            [Color(red: 0.18, green: 0.35, blue: 0.83), Color(red: 0.55, green: 0.74, blue: 1.0)]
        case .coral:
            [Color(red: 0.79, green: 0.18, blue: 0.27), Color(red: 1.0, green: 0.56, blue: 0.44)]
        case .violet:
            [Color(red: 0.39, green: 0.24, blue: 0.74), Color(red: 0.73, green: 0.55, blue: 1.0)]
        case .amber:
            [Color(red: 0.82, green: 0.47, blue: 0.06), Color(red: 1.0, green: 0.79, blue: 0.29)]
        case .sky:
            [Color(red: 0.07, green: 0.52, blue: 0.88), Color(red: 0.53, green: 0.86, blue: 1.0)]
        }
    }

    var primary: Color {
        colors.first ?? .blue
    }
}

import Foundation
import SwiftData
import SwiftUI

@Model
final class Tag {
    var id: UUID = UUID()
    var name: String = ""
    var colorHex: String = "6366F1"
    var createdAt: Date = Date()

    var color: Color {
        Color(hex: colorHex)
    }

    init(
        name: String = "",
        colorHex: String = "6366F1"
    ) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.createdAt = Date()
    }
}

// Predefined tag colors
enum TagColors {
    static let options: [(name: String, hex: String)] = [
        ("Indigo", "6366F1"),
        ("Paars", "8B5CF6"),
        ("Roze", "EC4899"),
        ("Rood", "EF4444"),
        ("Oranje", "F97316"),
        ("Geel", "EAB308"),
        ("Groen", "22C55E"),
        ("Teal", "14B8A6"),
        ("Blauw", "3B82F6"),
        ("Grijs", "6B7280")
    ]
}

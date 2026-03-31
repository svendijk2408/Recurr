import Foundation
import SwiftData

@Model
final class Account {
    var id: UUID = UUID()
    var name: String = ""
    var iconName: String = "creditcard.fill"
    var colorHex: String = "6366F1"
    var createdAt: Date = Date()

    init(
        name: String = "",
        iconName: String = "creditcard.fill",
        colorHex: String = "6366F1"
    ) {
        self.id = UUID()
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.createdAt = Date()
    }
}

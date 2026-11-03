import SwiftUI

enum Theme {
  static let shelf = Color.black
  static let ink = Color(red: 0.96, green: 0.96, blue: 0.96)
  static let muted = Color(red: 0.56, green: 0.56, blue: 0.58)
  static let card = Color(red: 0.11, green: 0.11, blue: 0.12)
  static let line = Color.white.opacity(0.08)
  static let dockFill = Color(red: 0.28, green: 0.28, blue: 0.31).opacity(0.55)
  static let accentA = Color(red: 1.0, green: 0.30, blue: 0.60)
  static let accentB = Color(red: 1.0, green: 0.54, blue: 0.24)
  static let pip = Color(red: 0.29, green: 0.87, blue: 0.50)

  static var dockGradient: LinearGradient {
    LinearGradient(colors: [accentA, accentB], startPoint: .leading, endPoint: .trailing)
  }

  static func coverGradient(for system: GameSystem) -> LinearGradient {
    let colors: [Color]
    switch system {
    case .gba: colors = [Color(red: 0.43, green: 0.30, blue: 0.60), Color(red: 0.14, green: 0.08, blue: 0.20)]
    case .gbc: colors = [Color(red: 0.49, green: 0.42, blue: 1.0), Color(red: 0.16, green: 0.13, blue: 0.35)]
    case .gb: colors = [Color(red: 0.45, green: 0.51, blue: 0.29), Color(red: 0.13, green: 0.15, blue: 0.09)]
    case .nes: colors = [Color(red: 0.82, green: 0.29, blue: 0.29), Color(red: 0.23, green: 0.08, blue: 0.08)]
    case .snes: colors = [Color(red: 0.42, green: 0.35, blue: 0.80), Color(red: 0.11, green: 0.09, blue: 0.22)]
    case .megaDrive: colors = [Color(red: 0.12, green: 0.44, blue: 0.92), Color(red: 0.05, green: 0.08, blue: 0.14)]
    }
    return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
  }
}

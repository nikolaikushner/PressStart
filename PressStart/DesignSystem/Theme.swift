import SwiftUI

enum Theme {
  /// Daylight wash of the original Game Boy LCD — pale yellow-green, not the later gray shells.
  static let shelfTop = Color(red: 0.925, green: 0.949, blue: 0.839)
  static let shelf = Color(red: 0.839, green: 0.878, blue: 0.690)
  static let ink = Color(red: 0.086, green: 0.141, blue: 0.047)
  static let muted = Color(red: 0.227, green: 0.290, blue: 0.133)
  static let card = Color(red: 0.957, green: 0.969, blue: 0.894)
  static let line = Color(red: 0.12, green: 0.18, blue: 0.06).opacity(0.14)
  static let dockFill = Color(red: 0.957, green: 0.969, blue: 0.894).opacity(0.92)
  static let accentA = Color(red: 1.0, green: 0.30, blue: 0.60)
  static let accentB = Color(red: 1.0, green: 0.54, blue: 0.24)
  static let pip = Color(red: 0.29, green: 0.87, blue: 0.50)
  static let boxDepth = Color(red: 0.141, green: 0.173, blue: 0.071)
  static let boxShadow = Color(red: 0.12, green: 0.16, blue: 0.05).opacity(0.36)

  static let shelfSurfaceTop = Color(red: 0.659, green: 0.722, blue: 0.439)
  static let shelfSurfaceBottom = Color(red: 0.549, green: 0.612, blue: 0.337)
  static let shelfLipTop = Color(red: 0.424, green: 0.478, blue: 0.251)
  static let shelfLipBottom = Color(red: 0.290, green: 0.337, blue: 0.165)

  static var shelfBackground: LinearGradient {
    LinearGradient(colors: [shelfTop, shelf], startPoint: .top, endPoint: .bottom)
  }

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

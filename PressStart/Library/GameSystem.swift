import UniformTypeIdentifiers

enum GameSystem: String, Codable, CaseIterable, Identifiable, Hashable {
  case gba, gbc, gb, nes, snes, megaDrive

  var id: String { rawValue }

  var short: String {
    switch self {
    case .gba: return "GBA"
    case .gbc: return "GBC"
    case .gb: return "GB"
    case .nes: return "NES"
    case .snes: return "SNES"
    case .megaDrive: return "MD"
    }
  }

  var label: String {
    switch self {
    case .gba: return "Game Boy Advance"
    case .gbc: return "Game Boy Color"
    case .gb: return "Game Boy"
    case .nes: return "NES"
    case .snes: return "SNES"
    case .megaDrive: return "Mega Drive"
    }
  }

  var skin: SkinKind {
    switch self {
    case .gb, .gbc, .nes: return .pocket
    case .gba, .snes, .megaDrive: return .advance
    }
  }

  var extensions: [String] {
    switch self {
    case .gba: return ["gba"]
    case .gbc: return ["gbc"]
    case .gb: return ["gb"]
    case .nes: return ["nes", "unf", "unif", "fds"]
    case .snes: return ["sfc", "smc", "fig"]
    case .megaDrive: return ["md", "gen", "smd"]
    }
  }

  var deltaGameType: String {
    switch self {
    case .gba: return "com.rileytestut.delta.game.gba"
    case .gbc, .gb: return "com.rileytestut.delta.game.gbc"
    case .nes: return "com.rileytestut.delta.game.nes"
    case .snes: return "com.rileytestut.delta.game.snes"
    case .megaDrive: return "com.rileytestut.delta.game.genesis"
    }
  }
}

enum SkinKind: String {
  case pocket, advance
}

enum GameSystems {
  static var importTypes: [UTType] {
    var types: [UTType] = [.data, .item]
    for system in GameSystem.allCases {
      for ext in system.extensions {
        if let type = UTType(filenameExtension: ext) {
          types.append(type)
        }
      }
    }
    if let zip = UTType(filenameExtension: "zip") {
      types.append(zip)
    }
    return types
  }

  static func system(forExtension ext: String) -> GameSystem? {
    let lower = ext.lowercased()
    return GameSystem.allCases.first { $0.extensions.contains(lower) }
  }
}

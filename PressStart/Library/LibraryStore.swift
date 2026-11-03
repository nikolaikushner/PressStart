import Foundation
import SwiftUI

enum AppPaths {
  static var documents: URL {
    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
  }

  static var romsDirectory: URL {
    documents.appendingPathComponent("ROMs", isDirectory: true)
  }

  static var savesDirectory: URL {
    documents.appendingPathComponent("Saves", isDirectory: true)
  }

  static var statesDirectory: URL {
    documents.appendingPathComponent("States", isDirectory: true)
  }

  static var coversDirectory: URL {
    documents.appendingPathComponent("Covers", isDirectory: true)
  }
}

@MainActor
final class LibraryStore: ObservableObject {
  @Published private(set) var games: [GameRecord] = []
  @Published var query = ""
  @Published var lastError: String?
  @Published var pendingSystemPick: PendingImport?

  struct PendingImport: Identifiable {
    let id = UUID()
    let data: Data
    let suggestedName: String
  }

  static var documents: URL { AppPaths.documents }
  static var romsDirectory: URL { AppPaths.romsDirectory }
  static var savesDirectory: URL { AppPaths.savesDirectory }
  static var statesDirectory: URL { AppPaths.statesDirectory }
  static var coversDirectory: URL { AppPaths.coversDirectory }

  private var catalogURL: URL {
    AppPaths.documents.appendingPathComponent("library.json")
  }

  var visible: [GameRecord] {
    let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    guard !q.isEmpty else { return games }
    return games.filter {
      "\($0.title) \($0.system.short)".lowercased().contains(q)
    }
  }

  var grouped: [(GameSystem, [GameRecord])] {
    var map: [GameSystem: [GameRecord]] = [:]
    for game in visible {
      map[game.system, default: []].append(game)
    }
    return GameSystem.allCases.compactMap { system in
      guard let items = map[system], !items.isEmpty else { return nil }
      return (system, items.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending })
    }
  }

  func reload() {
    ensureFolders()
    if let data = try? Data(contentsOf: catalogURL),
       let decoded = try? JSONDecoder().decode([GameRecord].self, from: data) {
      games = decoded.map { record in
        var next = record
        next.hasSave = FileManager.default.fileExists(atPath: stateURL(for: record.id).path)
          || FileManager.default.fileExists(atPath: sramURL(for: record).path)
        return next
      }
    } else {
      games = []
    }
  }

  func importFiles(_ urls: [URL]) {
    lastError = nil
    for url in urls {
      importOne(url)
    }
    persist()
  }

  func confirmPending(system: GameSystem) {
    guard let pending = pendingSystemPick else { return }
    pendingSystemPick = nil
    writeGame(data: pending.data, originalName: pending.suggestedName, system: system)
    persist()
  }

  func markSaved(gameID: String) {
    guard let index = games.firstIndex(where: { $0.id == gameID }) else { return }
    games[index].hasSave = true
    persist()
  }

  func setCover(gameID: String, imageData: Data) {
    ensureFolders()
    let url = Self.coversDirectory.appendingPathComponent("\(gameID).jpg")
    try? imageData.write(to: url, options: .atomic)
    guard let index = games.firstIndex(where: { $0.id == gameID }) else { return }
    games[index].coverPath = url.lastPathComponent
    persist()
  }

  func stateURL(for gameID: String) -> URL {
    Self.statesDirectory.appendingPathComponent("\(gameID).savestate")
  }

  func sramURL(for game: GameRecord) -> URL {
    Self.savesDirectory.appendingPathComponent("\(game.id).sav")
  }

  func coverURL(for game: GameRecord) -> URL? {
    guard let name = game.coverPath else { return nil }
    return Self.coversDirectory.appendingPathComponent(name)
  }

  private func importOne(_ url: URL) {
    let scoped = url.startAccessingSecurityScopedResource()
    defer { if scoped { url.stopAccessingSecurityScopedResource() } }
    do {
      let data = try Data(contentsOf: url)
      let name = url.lastPathComponent
      if let system = RomDetector.detect(data: data, filename: name) {
        writeGame(data: data, originalName: name, system: system)
      } else {
        pendingSystemPick = PendingImport(data: data, suggestedName: name)
      }
    } catch {
      lastError = error.localizedDescription
    }
  }

  private func writeGame(data: Data, originalName: String, system: GameSystem) {
    ensureFolders()
    let fileName = RomDetector.romFilename(originalName, system: system)
    let folder = Self.romsDirectory.appendingPathComponent(system.rawValue, isDirectory: true)
    try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    let dest = folder.appendingPathComponent(fileName)
    try? data.write(to: dest, options: .atomic)

    let id = "local:\(slug(fileName))"
    let record = GameRecord(
      id: id,
      title: RomDetector.prettyTitle(fileName),
      system: system,
      fileName: fileName,
      relativePath: "\(system.rawValue)/\(fileName)",
      addedAt: Date(),
      coverPath: games.first(where: { $0.id == id })?.coverPath,
      hasSave: games.first(where: { $0.id == id })?.hasSave ?? false
    )
    games.removeAll { $0.id == id }
    games.insert(record, at: 0)
  }

  private func persist() {
    ensureFolders()
    if let data = try? JSONEncoder().encode(games) {
      try? data.write(to: catalogURL, options: .atomic)
    }
  }

  private func ensureFolders() {
    let fm = FileManager.default
    for url in [Self.romsDirectory, Self.savesDirectory, Self.statesDirectory, Self.coversDirectory] {
      try? fm.createDirectory(at: url, withIntermediateDirectories: true)
    }
  }

  private func slug(_ value: String) -> String {
    let stem = (value as NSString).deletingPathExtension.lowercased()
    let cleaned = stem.replacingOccurrences(of: #"[^a-z0-9]+"#, with: "-", options: .regularExpression)
      .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    return cleaned.isEmpty ? "rom" : cleaned
  }
}

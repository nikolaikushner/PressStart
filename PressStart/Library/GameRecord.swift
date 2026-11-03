import Foundation

struct GameRecord: Identifiable, Codable, Hashable {
  var id: String
  var title: String
  var system: GameSystem
  var fileName: String
  var relativePath: String
  var addedAt: Date
  var coverPath: String?
  var hasSave: Bool

  var fileURL: URL {
    AppPaths.romsDirectory.appendingPathComponent(relativePath)
  }
}

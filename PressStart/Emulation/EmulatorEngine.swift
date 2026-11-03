import Foundation
import UIKit

@MainActor
protocol EmulatorEngine: AnyObject {
  var isRunning: Bool { get }
  func prepare(game: GameRecord) throws
  func makeGameView() -> UIViewController
  func start()
  func stop()
  func press(_ input: EngineInput, pressed: Bool)
  func saveState(to url: URL) throws
  func loadState(from url: URL) throws
  func saveSRAM(to url: URL) throws
  func loadSRAM(from url: URL) throws
  func captureCoverJPEG() -> Data?
}

enum EngineInput: Hashable {
  case a, b, x, y, start, select, up, down, left, right, l, r, menu
}

enum EngineError: LocalizedError {
  case coreMissing(GameSystem)
  case fileMissing
  case notReady
  case saveFailed

  var errorDescription: String? {
    switch self {
    case .coreMissing(let system):
      return "The \(system.label) core is not linked yet. Run scripts/bootstrap-cores.sh and open the workspace."
    case .fileMissing:
      return "The ROM file is missing."
    case .notReady:
      return "The emulator is still starting."
    case .saveFailed:
      return "Could not write the save."
    }
  }
}

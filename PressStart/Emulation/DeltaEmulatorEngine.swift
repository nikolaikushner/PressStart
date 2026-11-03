import UIKit
import DeltaCore

@MainActor
final class DeltaEmulatorEngine: NSObject, EmulatorEngine {
  private var gameRecord: GameRecord?
  private var deltaGame: Game?
  private weak var host: GameViewController?
  private let pad = SoftPadController()
  private(set) var isRunning = false

  func prepare(game: GameRecord) throws {
    guard CoreRegistry.shared.isReady(game.system) else {
      throw EngineError.coreMissing(game.system)
    }
    guard FileManager.default.fileExists(atPath: game.fileURL.path) else {
      throw EngineError.fileMissing
    }

    // Point battery saves into our Saves folder by using a sibling URL contract:
    // GameProtocol default places .sav next to the ROM; we copy ROM into a working dir.
    let work = AppPaths.savesDirectory.appendingPathComponent(game.id, isDirectory: true)
    try? FileManager.default.createDirectory(at: work, withIntermediateDirectories: true)
    let romURL = work.appendingPathComponent(game.fileName)
    if !FileManager.default.fileExists(atPath: romURL.path) {
      try FileManager.default.copyItem(at: game.fileURL, to: romURL)
    }

    let type = GameType(rawValue: game.system.deltaGameType)
    deltaGame = Game(fileURL: romURL, type: type)
    gameRecord = game
  }

  func makeGameView() -> UIViewController {
    let controller = GameViewController()
    controller.game = deltaGame
    controller.automaticallyPausesWhileInactive = true
    if let core = controller.emulatorCore {
      pad.bind(to: core)
    }
    host = controller
    return controller
  }

  func start() {
    host?.emulatorCore?.start()
    isRunning = host?.emulatorCore?.state == .running
  }

  func stop() {
    host?.emulatorCore?.stop()
    isRunning = false
  }

  func press(_ input: EngineInput, pressed: Bool) {
    guard let mapped = map(input) else { return }
    pad.set(mapped, pressed: pressed)
  }

  func saveState(to url: URL) throws {
    guard let core = host?.emulatorCore else { throw EngineError.notReady }
    _ = core.saveSaveState(to: url)
  }

  func loadState(from url: URL) throws {
    guard let core = host?.emulatorCore else { throw EngineError.notReady }
    guard let type = deltaGame?.type else { throw EngineError.notReady }
    try core.load(SaveState(fileURL: url, gameType: type))
  }

  func saveSRAM(to url: URL) throws {
    guard let core = host?.emulatorCore else { throw EngineError.notReady }
    core.save()
    let source = core.game.gameSaveURL
    if FileManager.default.fileExists(atPath: source.path) {
      if FileManager.default.fileExists(atPath: url.path) {
        try FileManager.default.removeItem(at: url)
      }
      try FileManager.default.copyItem(at: source, to: url)
    }
  }

  func loadSRAM(from url: URL) throws {
    guard let game = deltaGame else { throw EngineError.notReady }
    let dest = game.gameSaveURL
    if FileManager.default.fileExists(atPath: url.path) {
      if FileManager.default.fileExists(atPath: dest.path) {
        try FileManager.default.removeItem(at: dest)
      }
      try FileManager.default.copyItem(at: url, to: dest)
    }
  }

  func captureCoverJPEG() -> Data? {
    guard let view = host?.gameView else { return nil }
    let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
    let image = renderer.image { ctx in
      view.layer.render(in: ctx.cgContext)
    }
    return image.jpegData(compressionQuality: 0.72)
  }

  private func map(_ input: EngineInput) -> StandardGameControllerInput? {
    switch input {
    case .a: return .a
    case .b: return .b
    case .x: return .x
    case .y: return .y
    case .start: return .start
    case .select: return .select
    case .up: return .up
    case .down: return .down
    case .left: return .left
    case .right: return .right
    case .l: return .l1
    case .r: return .r1
    case .menu: return .menu
    }
  }
}

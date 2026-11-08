import DeltaCore
import SwiftUI
import UIKit

struct PlayView: View {
  @EnvironmentObject private var library: LibraryStore
  @EnvironmentObject private var gamepad: GamepadRouter
  @Environment(\.dismiss) private var dismiss

  let game: GameRecord

  @StateObject private var session = PlaySession()
  @State private var showMenu = false
  @State private var toast: String?
  @State private var bootError: String?

  private var layout: SkinLayout { SkinLayout.load(game.system.skin) }

  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()
      if layout.screen != nil {
        handheld
      } else {
        VStack(spacing: 0) {
          screen
          shell
        }
      }
    }
    .statusBarHidden(true)
    .toolbar(.hidden, for: .navigationBar)
    .onAppear(perform: boot)
    .onDisappear {
      session.shutdown(library: library, game: game)
      gamepad.engine = nil
    }
    .sheet(isPresented: $showMenu) {
      menuSheet
        .presentationDetents([.medium])
    }
    .overlay(alignment: .top) {
      if let toast {
        Text(toast)
          .font(.footnote.weight(.semibold))
          .padding(.horizontal, 12)
          .padding(.vertical, 8)
          .background(.black.opacity(0.85), in: Capsule())
          .foregroundStyle(.white)
          .padding(.top, 12)
      }
    }
    .alert("Could not start", isPresented: Binding(
      get: { bootError != nil },
      set: { if !$0 { bootError = nil } }
    )) {
      Button("Back", role: .cancel) { dismiss() }
    } message: {
      Text(bootError ?? "")
    }
  }

  /// Full handheld photo: the game is inset into the LCD, hits sit on the controls.
  private var handheld: some View {
    GeometryReader { geo in
      let picture = skinImage
      let pictureAspect = (picture?.size.width ?? 1) / (picture?.size.height ?? 1)
      let fittedW = min(geo.size.width, geo.size.height * pictureAspect)
      let fittedH = fittedW / pictureAspect
      let originX = (geo.size.width - fittedW) / 2
      let originY = (geo.size.height - fittedH) / 2
      ZStack {
        if let picture {
          Image(uiImage: picture)
            .resizable()
            .frame(width: fittedW, height: fittedH)
            .position(x: originX + fittedW / 2, y: originY + fittedH / 2)
        }
        if let hole = layout.screen {
          let box = CGRect(
            x: originX + hole.x * fittedW,
            y: originY + hole.y * fittedH,
            width: hole.w * fittedW,
            height: hole.h * fittedH
          )
          let gameW = min(box.width, box.height * aspect.w / aspect.h)
          let gameH = gameW * aspect.h / aspect.w
          gameSurface
            .frame(width: gameW, height: gameH)
            .position(x: box.midX, y: box.midY)
        }
        ForEach(layout.buttons) { button in
          let rect = CGRect(
            x: originX + button.x * fittedW,
            y: originY + button.y * fittedH,
            width: button.w * fittedW,
            height: button.h * fittedH
          )
          SkinHit(button: button.btn) { pressed in
            handleHit(button.btn, pressed: pressed)
          }
          .frame(width: rect.width, height: rect.height)
          .position(x: rect.midX, y: rect.midY)
        }
      }
    }
    .ignoresSafeArea()
  }

  private var gameSurface: some View {
    ZStack {
      Color(white: 0.03)
      if let controller = session.controller {
        GameHost(controller: controller)
          .clipShape(Rectangle())
      }
    }
  }

  private var skinImage: UIImage? {
    UIImage(named: layout.imageName, in: .main, compatibleWith: nil)
      ?? UIImage(contentsOfFile: Bundle.main.path(forResource: layout.imageName, ofType: "png", inDirectory: "Skins") ?? "")
  }

  private var screen: some View {
    GeometryReader { geo in
      let ratio = aspect
      let width = min(geo.size.width, geo.size.height * ratio.w / ratio.h)
      let height = width * ratio.h / ratio.w
      gameSurface
      .frame(width: width, height: height)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    .frame(maxHeight: .infinity)
  }

  private var shell: some View {
    ZStack {
      if let uiImage = skinImage {
        Image(uiImage: uiImage)
          .resizable()
          .scaledToFit()
          .frame(maxWidth: .infinity)
      } else {
        Color(white: 0.18).frame(height: 280)
      }

      GeometryReader { geo in
        ForEach(layout.buttons) { button in
          let rect = CGRect(
            x: button.x * geo.size.width,
            y: button.y * geo.size.height,
            width: button.w * geo.size.width,
            height: button.h * geo.size.height
          )
          SkinHit(button: button.btn) { pressed in
            handleHit(button.btn, pressed: pressed)
          }
          .frame(width: rect.width, height: rect.height)
          .position(x: rect.midX, y: rect.midY)
        }
      }
    }
    .frame(maxWidth: .infinity)
  }

  private var menuSheet: some View {
    NavigationStack {
      List {
        Button("Back") {
          showMenu = false
          session.shutdown(library: library, game: game)
          dismiss()
        }
        Button("Save") {
          showMenu = false
          flash(session.save(library: library, game: game))
        }
        Button("Load") {
          showMenu = false
          flash(session.load(library: library, game: game))
        }
        Button("Restart") {
          showMenu = false
          session.restart()
        }
        Button("Close", role: .cancel) { showMenu = false }
      }
      .navigationTitle(game.title)
    }
  }

  private var aspect: (w: CGFloat, h: CGFloat) {
    switch game.system {
    case .gb, .gbc: return (10, 9)
    case .gba: return (3, 2)
    default: return (4, 3)
    }
  }

  private func boot() {
    do {
      try session.prepare(game: game)
      gamepad.engine = session.engine
      session.start()
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
        session.loadSRAM(library: library, game: game)
        _ = session.load(library: library, game: game, quiet: true)
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
        session.captureCover(library: library, game: game)
      }
    } catch {
      bootError = error.localizedDescription
    }
  }

  private func handleHit(_ name: String, pressed: Bool) {
    if name == "menu" {
      if pressed { showMenu = true }
      return
    }
    guard let input = EngineInput.from(button: name) else { return }
    session.engine.press(input, pressed: pressed)
  }

  private func flash(_ message: String?) {
    guard let message else { return }
    toast = message
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
      if toast == message { toast = nil }
    }
  }
}

struct SkinHit: View {
  let button: String
  var onChange: (Bool) -> Void
  @State private var down = false

  var body: some View {
    Color.clear
      .contentShape(Rectangle())
      .gesture(
        DragGesture(minimumDistance: 0)
          .onChanged { _ in
            if !down {
              down = true
              onChange(true)
            }
          }
          .onEnded { _ in
            if down {
              down = false
              // Hold briefly so short taps register in the core.
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.09) {
                onChange(false)
              }
            }
          }
      )
      .accessibilityLabel(button)
  }
}

struct GameHost: UIViewControllerRepresentable {
  let controller: UIViewController
  func makeUIViewController(context: Context) -> UIViewController { controller }
  func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

@MainActor
final class PlaySession: ObservableObject {
  let engine: EmulatorEngine = DeltaEmulatorEngine()
  private(set) var controller: UIViewController?

  func prepare(game: GameRecord) throws {
    try engine.prepare(game: game)
    controller = engine.makeGameView()
  }

  func start() {
    engine.start()
    // Hide Delta's built-in controller chrome; we draw our own shell.
    if let gameVC = controller as? GameViewController {
      gameVC.controllerView?.isHidden = true
    }
  }

  func restart() {
    engine.stop()
    engine.start()
  }

  func save(library: LibraryStore, game: GameRecord) -> String? {
    do {
      try engine.saveSRAM(to: library.sramURL(for: game))
      try engine.saveState(to: library.stateURL(for: game.id))
      library.markSaved(gameID: game.id)
      return "Saved"
    } catch {
      return error.localizedDescription
    }
  }

  func load(library: LibraryStore, game: GameRecord, quiet: Bool = false) -> String? {
    let url = library.stateURL(for: game.id)
    guard FileManager.default.fileExists(atPath: url.path) else {
      return quiet ? nil : "No save"
    }
    do {
      try engine.loadState(from: url)
      return quiet ? "Resuming" : "Loaded"
    } catch {
      return quiet ? nil : error.localizedDescription
    }
  }

  func loadSRAM(library: LibraryStore, game: GameRecord) {
    let url = library.sramURL(for: game)
    try? engine.loadSRAM(from: url)
  }

  func captureCover(library: LibraryStore, game: GameRecord) {
    guard let data = engine.captureCoverJPEG() else { return }
    library.setCover(gameID: game.id, imageData: data)
  }

  func shutdown(library: LibraryStore, game: GameRecord) {
    _ = save(library: library, game: game)
    captureCover(library: library, game: game)
    engine.stop()
  }
}

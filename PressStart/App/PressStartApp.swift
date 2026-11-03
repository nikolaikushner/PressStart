import SwiftUI

@main
struct PressStartApp: App {
  @StateObject private var library = LibraryStore()
  @StateObject private var gamepad = GamepadRouter()

  var body: some Scene {
    WindowGroup {
      RootView()
        .environmentObject(library)
        .environmentObject(gamepad)
        .preferredColorScheme(.dark)
        .task {
          CoreRegistry.shared.bootstrap()
          gamepad.start()
          library.reload()
        }
    }
  }
}

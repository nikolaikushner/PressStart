import SwiftUI

struct RootView: View {
  @EnvironmentObject private var library: LibraryStore
  @State private var path = NavigationPath()
  @State private var showImporter = false

  var body: some View {
    NavigationStack(path: $path) {
      LibraryView(onOpen: { game in
        path.append(game)
      }, onAdd: {
        showImporter = true
      })
      .navigationDestination(for: GameRecord.self) { game in
        PlayView(game: game)
      }
    }
    .fileImporter(
      isPresented: $showImporter,
      allowedContentTypes: GameSystems.importTypes,
      allowsMultipleSelection: true
    ) { result in
      switch result {
      case .success(let urls):
        library.importFiles(urls)
      case .failure(let error):
        library.lastError = error.localizedDescription
      }
    }
  }
}

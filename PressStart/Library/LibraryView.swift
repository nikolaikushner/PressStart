import SwiftUI
import UIKit

struct LibraryView: View {
  @EnvironmentObject private var library: LibraryStore
  var onOpen: (GameRecord) -> Void
  var onAdd: () -> Void
  @State private var gamePendingDelete: GameRecord?

  var body: some View {
    ZStack(alignment: .bottom) {
      ShelfBackdrop()

      ScrollView {
        VStack(alignment: .leading, spacing: 18) {
          header
          searchField
          if library.visible.isEmpty {
            emptyState
          } else {
            ForEach(library.grouped, id: \.0) { system, games in
              section(system: system, games: games)
            }
          }
        }
        .padding(.horizontal, 22)
        .padding(.top, 12)
        .padding(.bottom, 120)
      }

      dock
    }
    .preferredColorScheme(.light)
    .toolbar(.hidden, for: .navigationBar)
    .sheet(item: $library.pendingSystemPick) { pending in
      SystemPickerSheet(fileName: pending.suggestedName) { system in
        library.confirmPending(system: system)
      }
    }
    .alert("Could not add game", isPresented: Binding(
      get: { library.lastError != nil },
      set: { if !$0 { library.lastError = nil } }
    )) {
      Button("OK", role: .cancel) { library.lastError = nil }
    } message: {
      Text(library.lastError ?? "")
    }
    .alert(
      "Remove from shelf?",
      isPresented: Binding(
        get: { gamePendingDelete != nil },
        set: { if !$0 { gamePendingDelete = nil } }
      ),
      presenting: gamePendingDelete
    ) { game in
      Button("Delete", role: .destructive) {
        library.delete(game)
        gamePendingDelete = nil
      }
      Button("Cancel", role: .cancel) { gamePendingDelete = nil }
    } message: { game in
      Text("“\(game.title)” will be removed from this device, including its save data.")
    }
  }

  private var header: some View {
    HStack {
      Spacer()
      Text("PRESS START")
        .font(.system(size: 20, weight: .heavy, design: .rounded))
        .tracking(4)
        .foregroundStyle(Theme.ink)
      Spacer()
      NavigationLink {
        LicensesView()
      } label: {
        Image(systemName: "info.circle")
          .foregroundStyle(Theme.muted)
      }
      .accessibilityLabel("Licenses")
    }
    .padding(.vertical, 10)
  }

  private var searchField: some View {
    HStack(spacing: 8) {
      Image(systemName: "magnifyingglass")
        .foregroundStyle(Theme.muted)
      TextField("Search games", text: $library.query)
        .textInputAutocapitalization(.never)
        .disableAutocorrection(true)
        .foregroundStyle(Theme.ink)
        .tint(Theme.ink)
    }
    .padding(.horizontal, 12)
    .frame(height: 40)
    .background(Theme.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .strokeBorder(Theme.line, lineWidth: 1)
    }
    .shadow(color: Theme.boxShadow.opacity(0.35), radius: 4, y: 2)
  }

  private var emptyState: some View {
    VStack(spacing: 10) {
      Text("Nothing on the shelf yet")
        .font(.headline)
        .foregroundStyle(Theme.ink)
      Text("Tap Add and choose a ROM you own. Game Boy, GBA, NES, SNES, and Mega Drive are supported.")
        .font(.subheadline)
        .foregroundStyle(Theme.muted)
        .multilineTextAlignment(.center)
      if CoreRegistry.shared.registeredSystems.isEmpty {
        Text("System cores are not linked yet. Run PressStart/scripts/bootstrap-cores.sh, then add the Vendor frameworks in Xcode.")
          .font(.caption)
          .foregroundStyle(Theme.muted.opacity(0.9))
          .multilineTextAlignment(.center)
          .padding(.top, 6)
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.top, 48)
  }

  private func section(system: GameSystem, games: [GameRecord]) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text(system.short)
          .font(.title3.weight(.bold))
          .foregroundStyle(Theme.ink)
        Spacer()
        Text(games.count == 1 ? "1 game" : "\(games.count) games")
          .font(.caption)
          .foregroundStyle(Theme.muted)
      }
      GameShelves(games: games, onOpen: onOpen) { game in
        gamePendingDelete = game
      }
    }
  }

  private var dock: some View {
    HStack(spacing: 4) {
      Label("Games", systemImage: "gamecontroller.fill")
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .frame(height: 36)
        .background(Theme.dockGradient, in: Capsule())

      Button(action: onAdd) {
        Label("Add", systemImage: "plus")
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(Theme.ink)
          .padding(.horizontal, 14)
          .frame(height: 36)
      }
    }
    .padding(5)
    .background(Theme.dockFill, in: Capsule())
    .overlay(Capsule().stroke(Theme.line, lineWidth: 1))
    .shadow(color: Theme.boxShadow.opacity(0.7), radius: 14, y: 6)
    .padding(.bottom, 14)
  }
}

private struct ShelfBackdrop: View {
  var body: some View {
    ZStack {
      Theme.shelfBackground
      RadialGradient(
        colors: [
          Color.white.opacity(0.28),
          Color.white.opacity(0.05),
          Color(red: 0.25, green: 0.32, blue: 0.10).opacity(0.10)
        ],
        center: .top,
        startRadius: 20,
        endRadius: 560
      )
    }
    .ignoresSafeArea()
  }
}

private struct GameShelves: View {
  let games: [GameRecord]
  var onOpen: (GameRecord) -> Void
  var onDelete: (GameRecord) -> Void
  @State private var width: CGFloat = UIScreen.main.bounds.width - 44

  private let spacing: CGFloat = 12
  private let minBox: CGFloat = 88
  private let maxBox: CGFloat = 136

  var body: some View {
    let columns = columnCount(for: width)
    let rows = games.chunks(of: columns)
    VStack(spacing: 22) {
      ForEach(rows.indices, id: \.self) { index in
        shelfRow(rows[index], columns: columns)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .background {
      GeometryReader { geo in
        Color.clear.preference(key: ShelfWidthKey.self, value: geo.size.width)
      }
    }
    .onPreferenceChange(ShelfWidthKey.self) { width = $0 }
  }

  private func columnCount(for width: CGFloat) -> Int {
    guard width > 1 else { return 3 }
    var columns = max(2, Int((width + spacing) / (minBox + spacing)))
    var box = (width - spacing * CGFloat(columns - 1)) / CGFloat(columns)
    while box > maxBox {
      columns += 1
      box = (width - spacing * CGFloat(columns - 1)) / CGFloat(columns)
    }
    return columns
  }

  private func shelfRow(_ row: [GameRecord], columns: Int) -> some View {
    VStack(spacing: -4) {
      HStack(alignment: .bottom, spacing: spacing) {
        ForEach(row) { game in
          gameButton(game)
        }
        if row.count < columns {
          ForEach(0..<(columns - row.count), id: \.self) { _ in
            Color.clear.frame(maxWidth: .infinity)
          }
        }
      }
      .padding(.horizontal, 8)
      .zIndex(1)

      ShelfBoard {
        HStack(alignment: .top, spacing: spacing) {
          ForEach(row) { game in
            Button {
              onOpen(game)
            } label: {
              Text(game.title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Theme.ink)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 28, alignment: .top)
            }
            .buttonStyle(.plain)
            .accessibilityHidden(true)
          }
          if row.count < columns {
            ForEach(0..<(columns - row.count), id: \.self) { _ in
              Color.clear.frame(maxWidth: .infinity, minHeight: 28)
            }
          }
        }
      }
    }
  }

  private func gameButton(_ game: GameRecord) -> some View {
    Button {
      onOpen(game)
    } label: {
      GameCardView(game: game)
    }
    .buttonStyle(.plain)
    .contextMenu {
      Button("Delete", systemImage: "trash", role: .destructive) {
        onDelete(game)
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(game.title)
    .accessibilityAddTraits(.isButton)
    .accessibilityAction(named: "Delete") {
      onDelete(game)
    }
    .frame(maxWidth: .infinity)
  }
}

private struct ShelfBoard<Labels: View>: View {
  @ViewBuilder var labels: () -> Labels

  var body: some View {
    VStack(spacing: 0) {
      labels()
        .padding(.horizontal, 8)
        .padding(.top, 12)
        .padding(.bottom, 6)
        .frame(maxWidth: .infinity)
        .background(
          LinearGradient(
            colors: [Theme.shelfSurfaceTop, Theme.shelfSurfaceBottom],
            startPoint: .top,
            endPoint: .bottom
          )
        )
      ZStack(alignment: .top) {
        LinearGradient(
          colors: [Theme.shelfLipTop, Theme.shelfLipBottom],
          startPoint: .top,
          endPoint: .bottom
        )
        Rectangle()
          .fill(Color.white.opacity(0.28))
          .frame(height: 1)
      }
      .frame(height: 8)
    }
    .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
    .shadow(color: Theme.boxShadow.opacity(0.85), radius: 5, y: 4)
  }
}

private struct ShelfWidthKey: PreferenceKey {
  static var defaultValue: CGFloat = 0
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = nextValue()
  }
}

private extension Array {
  func chunks(of size: Int) -> [[Element]] {
    guard size > 0, !isEmpty else { return isEmpty ? [] : [self] }
    return stride(from: 0, to: count, by: size).map {
      Array(self[$0..<Swift.min($0 + size, count)])
    }
  }
}

struct GameCardView: View {
  @EnvironmentObject private var library: LibraryStore
  let game: GameRecord

  var body: some View {
    box
  }

  private var box: some View {
    ZStack(alignment: .topLeading) {
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .fill(
          LinearGradient(
            colors: [
              Theme.boxDepth.opacity(0.78),
              Theme.boxDepth
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )

      cover
        .padding(.trailing, 5)
        .padding(.bottom, 6)
    }
    .aspectRatio(0.74, contentMode: .fit)
    .compositingGroup()
    .shadow(color: Theme.boxShadow, radius: 4, x: 1.5, y: 4)
  }

  private var cover: some View {
    RoundedRectangle(cornerRadius: 6, style: .continuous)
      .fill(Theme.coverGradient(for: game.system))
      .overlay {
        if let cover = library.coverURL(for: game),
           let image = UIImage(contentsOfFile: cover.path) {
          Image(uiImage: image)
            .resizable()
            .scaledToFill()
        } else {
          VStack(alignment: .leading, spacing: 6) {
            Text(game.system.short)
              .font(.caption2.weight(.semibold))
              .foregroundStyle(.white.opacity(0.75))
            Text(game.title)
              .font(.caption.weight(.bold))
              .foregroundStyle(.white)
              .lineLimit(3)
              .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
          }
          .padding(8)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
      }
      .overlay(alignment: .top) {
        LinearGradient(
          colors: [Color.white.opacity(0.32), Color.white.opacity(0)],
          startPoint: .top,
          endPoint: .bottom
        )
        .frame(height: 18)
        .allowsHitTesting(false)
      }
      .overlay(alignment: .topTrailing) {
        if game.hasSave {
          Circle()
            .fill(Theme.pip)
            .frame(width: 8, height: 8)
            .padding(7)
            .shadow(color: .black.opacity(0.28), radius: 1, y: 1)
        }
      }
      .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
      .overlay {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
          .strokeBorder(
            LinearGradient(
              colors: [
                Color.white.opacity(0.62),
                Color.white.opacity(0.08),
                Color.black.opacity(0.28)
              ],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            ),
            lineWidth: 1
          )
      }
  }
}

struct SystemPickerSheet: View {
  let fileName: String
  var onPick: (GameSystem) -> Void
  @Environment(\.dismiss) private var dismiss
  @State private var system: GameSystem = .nes

  var body: some View {
    NavigationStack {
      Form {
        Section("Could not tell the console for") {
          Text(fileName).font(.footnote).foregroundStyle(.secondary)
          Picker("Console", selection: $system) {
            ForEach(GameSystem.allCases) { item in
              Text(item.label).tag(item)
            }
          }
        }
      }
      .navigationTitle("Choose console")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Add") {
            onPick(system)
            dismiss()
          }
        }
      }
    }
    .presentationDetents([.medium])
  }
}

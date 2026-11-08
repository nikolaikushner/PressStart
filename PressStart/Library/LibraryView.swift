import SwiftUI
import UIKit

struct LibraryView: View {
  @EnvironmentObject private var library: LibraryStore
  var onOpen: (GameRecord) -> Void
  var onAdd: () -> Void
  @State private var gamePendingDelete: GameRecord?

  var body: some View {
    ZStack(alignment: .bottom) {
      Theme.shelf.ignoresSafeArea()

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
        .padding(.horizontal, 28)
        .padding(.top, 12)
        .padding(.bottom, 120)
      }

      dock
    }
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
    }
    .padding(.horizontal, 12)
    .frame(height: 40)
    .background(Theme.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        Text(system.short)
          .font(.title3.weight(.bold))
          .foregroundStyle(Theme.ink)
        Spacer()
        Text(games.count == 1 ? "1 game" : "\(games.count) games")
          .font(.caption)
          .foregroundStyle(Theme.muted)
      }
      LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 10)], spacing: 12) {
        ForEach(games) { game in
          Button {
            onOpen(game)
          } label: {
            GameCardView(game: game)
          }
          .buttonStyle(.plain)
          .contextMenu {
            Button("Delete", systemImage: "trash", role: .destructive) {
              gamePendingDelete = game
            }
          }
          .accessibilityAction(named: "Delete") {
            gamePendingDelete = game
          }
        }
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
    .overlay(Capsule().stroke(Color.white.opacity(0.16), lineWidth: 1))
    .padding(.bottom, 14)
  }
}

struct GameCardView: View {
  @EnvironmentObject private var library: LibraryStore
  let game: GameRecord

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      ZStack(alignment: .topTrailing) {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
          .fill(Theme.coverGradient(for: game.system))
          .aspectRatio(1 / 0.92, contentMode: .fit)
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
                  .foregroundStyle(.white.opacity(0.7))
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
          .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

        if game.hasSave {
          Circle()
            .fill(Theme.pip)
            .frame(width: 8, height: 8)
            .padding(8)
        }
      }
      Text(game.title)
        .font(.caption2)
        .foregroundStyle(Theme.muted)
        .lineLimit(2)
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

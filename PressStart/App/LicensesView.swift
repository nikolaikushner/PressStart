import SwiftUI

struct LicensesView: View {
  private let sourceURL = URL(string: "https://github.com/nikolaikushner/PressStart")!
  private let agplURL = URL(string: "https://www.gnu.org/licenses/agpl-3.0.html")!

  var body: some View {
    List {
      Section("Press Start") {
        Text("Press Start is free software under the GNU Affero General Public License v3.0 (AGPL-3.0). The official app may be sold on the App Store; corresponding source is always available on GitHub.")
          .font(.footnote)
          .foregroundStyle(.secondary)
        Link("Source on GitHub", destination: sourceURL)
        Link("AGPL-3.0 license text", destination: agplURL)
      }
      Section("Emulation") {
        Text("Gameplay uses DeltaCore and system cores (GBC, GBA, NES, SNES, Genesis Plus GX wrappers) by Riley Testut and contributors, also under AGPL-3.0. Press Start does not use Delta branding.")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
      Section("Skins") {
        Text("The Game Boy shell is a photograph of the original handheld, with the game drawn in the screen. The other shell is an original Press Start layout. Console trademarks are not claimed.")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
      Section("ROMs") {
        Text("Bring your own legally obtained backups. Press Start does not download or sell game ROMs.")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
    }
    .navigationTitle("Licenses")
  }
}

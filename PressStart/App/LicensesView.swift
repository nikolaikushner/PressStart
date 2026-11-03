import SwiftUI

struct LicensesView: View {
  var body: some View {
    List {
      Section("Press Start") {
        Text("Press Start is offered under the GNU Affero General Public License v3. Source: github.com/nikolaikushner/retro-games")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
      Section("Emulation") {
        Text("Gameplay uses DeltaCore and system cores (GBC, GBA, NES, SNES, Genesis Plus GX wrappers) by Riley Testut and contributors, also under AGPL-3.0. Press Start does not use Delta branding.")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
      Section("Skins") {
        Text("On-screen shells are adapted community controller layouts. Console trademarks are not claimed.")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
    }
    .navigationTitle("Licenses")
  }
}

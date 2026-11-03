import SwiftUI

struct LicensesView: View {
  var body: some View {
    List {
      Section("Press Start") {
        Text("Press Start UI and original app code are proprietary © Nikolai Kushner. The official app is sold on the App Store. You may not redistribute the source or unofficial builds without permission.")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
      Section("Emulation engines") {
        Text("Gameplay may use DeltaCore and system cores (GBC, GBA, NES, SNES, Genesis Plus GX wrappers). Those projects are AGPL-3.0. Linking them into a build triggers AGPL source obligations for that combined work. Press Start branding is independent of Delta.")
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

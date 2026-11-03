import Foundation
import DeltaCore

#if canImport(GBCDeltaCore)
import GBCDeltaCore
#endif
#if canImport(GBADeltaCore)
import GBADeltaCore
#endif
#if canImport(NESDeltaCore)
import NESDeltaCore
#endif
#if canImport(SNESDeltaCore)
import SNESDeltaCore
#endif
#if canImport(GPGXDeltaCore)
import GPGXDeltaCore
#endif

/// Registers Delta system cores when their frameworks are linked.
@MainActor
final class CoreRegistry {
  static let shared = CoreRegistry()

  private(set) var registeredSystems: Set<GameSystem> = []

  func bootstrap() {
    registeredSystems.removeAll()

    #if canImport(GBCDeltaCore)
    Delta.register(GBC.core)
    registeredSystems.insert(.gb)
    registeredSystems.insert(.gbc)
    #endif

    #if canImport(GBADeltaCore)
    Delta.register(GBA.core)
    registeredSystems.insert(.gba)
    #endif

    #if canImport(NESDeltaCore)
    Delta.register(NES.core)
    registeredSystems.insert(.nes)
    #endif

    #if canImport(SNESDeltaCore)
    Delta.register(SNES.core)
    registeredSystems.insert(.snes)
    #endif

    #if canImport(GPGXDeltaCore)
    Delta.register(GPGX.core)
    registeredSystems.insert(.megaDrive)
    #endif
  }

  func isReady(_ system: GameSystem) -> Bool {
    if system == .gb { return registeredSystems.contains(.gb) || registeredSystems.contains(.gbc) }
    return registeredSystems.contains(system)
  }
}

import Foundation

enum RomDetector {
  private static let gbLogo: [UInt8] = [
    0xCE, 0xED, 0x66, 0x66, 0xCC, 0x0D, 0x00, 0x0B, 0x03, 0x73, 0x00, 0x83, 0x00, 0x0C, 0x00, 0x0D,
  ]
  private static let gbaLogo: [UInt8] = [
    0x24, 0xFF, 0xAE, 0x51, 0x69, 0x9A, 0xA2, 0x21, 0x3D, 0x84, 0x82, 0x0A,
  ]

  static func detect(data: Data, filename: String) -> GameSystem? {
    let bytes = [UInt8](data)
    if bytesAt(bytes, 0, [0x4E, 0x45, 0x53, 0x1A]) { return .nes }
    if bytesAt(bytes, 0x04, gbaLogo) { return .gba }
    if bytesAt(bytes, 0x104, gbLogo) {
      let flag = bytes.count > 0x143 ? bytes[0x143] : 0
      return (flag == 0x80 || flag == 0xC0) ? .gbc : .gb
    }
    if textAt(bytes, 0x100, 4) == "SEGA" { return .megaDrive }
    if looksLikeSnes(bytes) { return .snes }

    let cleaned = filename
      .replacingOccurrences(of: #"(\.(heic|jpg|jpeg|png|webp|gif))+$"#, with: "", options: .regularExpression)
    let ext = (cleaned as NSString).pathExtension.lowercased()
    return GameSystems.system(forExtension: ext)
  }

  static func prettyTitle(_ filename: String) -> String {
    var name = filename.replacingOccurrences(
      of: #"(\.(heic|jpg|jpeg|png|webp|gif))+(?=\.|$)"#,
      with: "",
      options: .regularExpression
    )
    name = (name as NSString).deletingPathExtension
    name = name.replacingOccurrences(of: #"\s*[([].*?[)\]]"#, with: "", options: .regularExpression)
    name = name.replacingOccurrences(of: #"[._]+"#, with: " ", options: .regularExpression)
    name = name.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
      .trimmingCharacters(in: .whitespacesAndNewlines)
    return name.isEmpty ? filename : name
  }

  static func romFilename(_ filename: String, system: GameSystem) -> String {
    let ext = system.extensions[0]
    var cleaned = filename.replacingOccurrences(
      of: #"(\.(heic|jpg|jpeg|png|webp|gif))+$"#,
      with: "",
      options: .regularExpression
    )
    cleaned = (cleaned as NSString).deletingPathExtension
    if cleaned.isEmpty { cleaned = "game" }
    return "\(cleaned).\(ext)"
  }

  private static func bytesAt(_ bytes: [UInt8], _ offset: Int, _ signature: [UInt8]) -> Bool {
    guard offset >= 0, offset + signature.count <= bytes.count else { return false }
    for i in 0..<signature.count where bytes[offset + i] != signature[i] {
      return false
    }
    return true
  }

  private static func textAt(_ bytes: [UInt8], _ offset: Int, _ length: Int) -> String {
    guard offset >= 0, offset + length <= bytes.count else { return "" }
    var text = ""
    for i in 0..<length {
      let code = bytes[offset + i]
      text.append((code >= 32 && code < 127) ? Character(UnicodeScalar(code)) : " ")
    }
    return text
  }

  private static func looksLikeSnes(_ bytes: [UInt8]) -> Bool {
    for offset in [0x7FC0, 0xFFC0, 0x81C0, 0x101C0] {
      guard offset + 0x20 <= bytes.count else { continue }
      let complement = Int(bytes[offset + 0x1C]) | (Int(bytes[offset + 0x1D]) << 8)
      let checksum = Int(bytes[offset + 0x1E]) | (Int(bytes[offset + 0x1F]) << 8)
      if (complement ^ checksum) == 0xFFFF, checksum != 0, checksum != 0xFFFF {
        return true
      }
    }
    return false
  }
}

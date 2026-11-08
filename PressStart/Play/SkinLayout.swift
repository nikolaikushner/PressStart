import Foundation
import CoreGraphics

struct SkinButton: Identifiable {
  var id: String { btn }
  let btn: String
  let x: CGFloat
  let y: CGFloat
  let w: CGFloat
  let h: CGFloat
}

struct SkinScreen {
  let x: CGFloat
  let y: CGFloat
  let w: CGFloat
  let h: CGFloat
}

struct SkinLayout {
  let imageName: String
  let buttons: [SkinButton]
  /// When set, the picture is the whole handheld and the game sits in this rect.
  let screen: SkinScreen?

  static func load(_ kind: SkinKind) -> SkinLayout {
    let name = kind == .pocket ? "pocket" : "advance"
    guard
      let url = Bundle.main.url(forResource: name, withExtension: "json", subdirectory: "Skins")
        ?? Bundle.main.url(forResource: name, withExtension: "json"),
      let data = try? Data(contentsOf: url),
      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      let rawButtons = json["buttons"] as? [[String: Any]]
    else {
      return SkinLayout(imageName: name, buttons: [], screen: nil)
    }

    let screen = (json["screen"] as? [String: Any]).flatMap { item -> SkinScreen? in
      guard
        let x = item["x"] as? Double,
        let y = item["y"] as? Double,
        let w = item["w"] as? Double,
        let h = item["h"] as? Double
      else { return nil }
      return SkinScreen(x: CGFloat(x), y: CGFloat(y), w: CGFloat(w), h: CGFloat(h))
    }
    let hasScreen = screen != nil

    let buttons = rawButtons.compactMap { item -> SkinButton? in
      guard
        let btn = item["btn"] as? String,
        let x = item["x"] as? Double,
        let y = item["y"] as? Double,
        let w = item["w"] as? Double,
        let h = item["h"] as? Double
      else { return nil }
      let pad: CGFloat
      if hasScreen {
        pad = 0.006
      } else if btn == "start" || btn == "select" {
        pad = 0.05
      } else if btn == "menu" {
        pad = 0.03
      } else {
        pad = 0.014
      }
      var rx = CGFloat(x) - pad
      var ry = CGFloat(y) - pad
      var rw = CGFloat(w) + pad * 2
      var rh = CGFloat(h) + pad * 2
      if rx < 0 { rw += rx; rx = 0 }
      if ry < 0 { rh += ry; ry = 0 }
      if rx + rw > 1 { rw = 1 - rx }
      if ry + rh > 1 { rh = 1 - ry }
      return SkinButton(btn: btn, x: rx, y: ry, w: rw, h: rh)
    }
    return SkinLayout(imageName: name, buttons: buttons, screen: screen)
  }
}

extension EngineInput {
  static func from(button: String) -> EngineInput? {
    switch button {
    case "a": return .a
    case "b": return .b
    case "x": return .x
    case "y": return .y
    case "start": return .start
    case "select": return .select
    case "up": return .up
    case "down": return .down
    case "left": return .left
    case "right": return .right
    case "l": return .l
    case "r": return .r
    case "menu": return .menu
    default: return nil
    }
  }
}

import Combine
import GameController
import QuartzCore
import SwiftUI

@MainActor
final class GamepadRouter: ObservableObject {
  @Published private(set) var connectedName: String?
  weak var engine: EmulatorEngine?

  private var holders: [Any] = []
  private var previous = Set<EngineInput>()
  private var displayLink: CADisplayLink?
  private var latched: [EngineInput: CFTimeInterval] = [:]

  func start() {
    let center = NotificationCenter.default
    holders.append(center.addObserver(forName: .GCControllerDidConnect, object: nil, queue: .main) { [weak self] _ in
      Task { @MainActor in self?.refresh() }
    })
    holders.append(center.addObserver(forName: .GCControllerDidDisconnect, object: nil, queue: .main) { [weak self] _ in
      Task { @MainActor in self?.refresh() }
    })
    refresh()
    let link = CADisplayLink(target: self, selector: #selector(tick))
    link.add(to: .main, forMode: .common)
    displayLink = link
  }

  func refresh() {
    connectedName = GCController.controllers().first?.vendorName ?? GCController.controllers().first?.productCategory
  }

  @objc private func tick() {
    guard let engine else { return }
    let pads = GCController.controllers()
    var next = Set<EngineInput>()
    for pad in pads {
      if let gamepad = pad.extendedGamepad {
        if gamepad.buttonA.isPressed { next.insert(.a) }
        if gamepad.buttonB.isPressed { next.insert(.b) }
        if gamepad.buttonX.isPressed { next.insert(.x) }
        if gamepad.buttonY.isPressed { next.insert(.y) }
        if gamepad.buttonMenu.isPressed { next.insert(.start) }
        if gamepad.buttonOptions?.isPressed == true { next.insert(.select) }
        if gamepad.leftShoulder.isPressed { next.insert(.l) }
        if gamepad.rightShoulder.isPressed { next.insert(.r) }
        if gamepad.dpad.up.isPressed || gamepad.leftThumbstick.yAxis.value > 0.55 { next.insert(.up) }
        if gamepad.dpad.down.isPressed || gamepad.leftThumbstick.yAxis.value < -0.55 { next.insert(.down) }
        if gamepad.dpad.left.isPressed || gamepad.leftThumbstick.xAxis.value < -0.55 { next.insert(.left) }
        if gamepad.dpad.right.isPressed || gamepad.leftThumbstick.xAxis.value > 0.55 { next.insert(.right) }
      } else if let micro = pad.microGamepad {
        if micro.buttonA.isPressed { next.insert(.a) }
        if micro.buttonX.isPressed { next.insert(.b) }
        if micro.buttonMenu.isPressed { next.insert(.start) }
        if micro.dpad.up.isPressed { next.insert(.up) }
        if micro.dpad.down.isPressed { next.insert(.down) }
        if micro.dpad.left.isPressed { next.insert(.left) }
        if micro.dpad.right.isPressed { next.insert(.right) }
      }
    }

    let now = CACurrentMediaTime()
    for input in next { latched[input] = now + 0.08 }
    latched = latched.filter { next.contains($0.key) || $0.value > now }
    let active = next.union(Set(latched.keys))

    for input in active where !previous.contains(input) {
      engine.press(input, pressed: true)
    }
    for input in previous where !active.contains(input) {
      engine.press(input, pressed: false)
    }
    previous = active
  }
}

import Foundation
import DeltaCore

final class SoftPadController: NSObject, GameController {
  let name = "Press Start Pad"
  var playerIndex: Int? = 0
  let inputType: GameControllerInputType = .standard
  var defaultInputMapping: GameControllerInputMappingProtocol?

  func bind(to core: EmulatorCore) {
    if defaultInputMapping == nil,
       let url = core.deltaCore.resourceBundle.url(forResource: "Standard", withExtension: "deltamapping") {
      defaultInputMapping = try? GameControllerInputMapping(fileURL: url)
    }
    addReceiver(core, inputMapping: defaultInputMapping)
  }

  func set(_ input: StandardGameControllerInput, pressed: Bool) {
    if pressed {
      activate(input, value: 1)
    } else {
      deactivate(input)
    }
  }
}

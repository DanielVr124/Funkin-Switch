package nx.controls;

#if switch
import haxe.Int64;
import funkin.input.PreciseInputManager;
import funkin.play.notes.NoteDirection;
import nx.NXMain;
import nx.controls.NXControlButton;

class NXPreciseInputHandler
{
  public var onButtonPressed:Null<(NoteDirection, Int64, Int) -> Void> = null;
  public var onButtonReleased:Null<(NoteDirection, Int64, Int) -> Void> = null;

  private var _previousButtonStates:Map<NXControlButton, Bool> = new Map();
  private var _awaitingNeutralInput:Bool = false;

  public function new() {}

  /**
   * Update the input handler - should be called every frame.
   * Checks for button state changes and dispatches events.
   */
  public function update():Void
  {
    var controller = NXMain.nxController;
    if (controller == null) return;

    final timestamp = getCurrentTimestamp();
    final mappedInputs = getMappedInputs();

    // Release any sustained notes as soon as the controller becomes unusable.
    if (!controller.isConnected)
    {
      for (input in mappedInputs)
      {
        checkButton(controller, input.button, input.direction, timestamp, input.code);
      }
      _awaitingNeutralInput = true;
      return;
    }

    // The button used to reconnect must not become an accidental note hit.
    // Wait until all buttons in the selected layout have been released.
    if (_awaitingNeutralInput)
    {
      for (input in mappedInputs)
      {
        if (controller.isPressed(input.button)) return;
      }

      _previousButtonStates.clear();
      _awaitingNeutralInput = false;
      return;
    }

    for (input in mappedInputs)
    {
      checkButton(controller, input.button, input.direction, timestamp, input.code);
    }
  }

  private function getMappedInputs():Array<{button:NXControlButton, direction:NoteDirection, code:Int}>
  {
    return switch (funkin.Preferences.switchNoteInputLayout)
    {
      case 'DPad':
        [
          {button: UP, direction: NoteDirection.UP, code: 0},
          {button: DOWN, direction: NoteDirection.DOWN, code: 1},
          {button: LEFT, direction: NoteDirection.LEFT, code: 2},
          {button: RIGHT, direction: NoteDirection.RIGHT, code: 3}
        ];
      case 'FaceButtons':
        [
          {button: X, direction: NoteDirection.UP, code: 4},
          {button: B, direction: NoteDirection.DOWN, code: 5},
          {button: Y, direction: NoteDirection.LEFT, code: 6},
          {button: A, direction: NoteDirection.RIGHT, code: 7}
        ];
      case 'Shoulders':
        [
          {button: R, direction: NoteDirection.UP, code: 10},
          {button: ZL, direction: NoteDirection.DOWN, code: 9},
          {button: L, direction: NoteDirection.LEFT, code: 8},
          {button: ZR, direction: NoteDirection.RIGHT, code: 11}
        ];
      default:
        [
          {button: UP, direction: NoteDirection.UP, code: 0},
          {button: DOWN, direction: NoteDirection.DOWN, code: 1},
          {button: LEFT, direction: NoteDirection.LEFT, code: 2},
          {button: RIGHT, direction: NoteDirection.RIGHT, code: 3},
          {button: X, direction: NoteDirection.UP, code: 4},
          {button: B, direction: NoteDirection.DOWN, code: 5},
          {button: Y, direction: NoteDirection.LEFT, code: 6},
          {button: A, direction: NoteDirection.RIGHT, code: 7}
        ];
    };
  }

  private function checkButton(controller:NXController, button:NXControlButton, direction:NoteDirection, timestamp:Int64, buttonCode:Int):Void
  {
    var currentState:Bool = controller.isPressed(button);
    var previousState:Bool = _previousButtonStates.get(button) ?? false;

    if (currentState && !previousState)
    {
      if (onButtonPressed != null) onButtonPressed(direction, timestamp, buttonCode);
    }
    else if (!currentState && previousState)
    {
      if (onButtonReleased != null) onButtonReleased(direction, timestamp, buttonCode);
    }

    _previousButtonStates.set(button, currentState);
  }

  private static function getCurrentTimestamp():Int64
  {
    return PreciseInputManager.getCurrentTimestamp();
  }

  public function destroy():Void
  {
    onButtonPressed = null;
    onButtonReleased = null;
  }
}
#end

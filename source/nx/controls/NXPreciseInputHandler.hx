package nx.controls;

#if switch
import haxe.Int64;
import funkin.input.PreciseInputManager;
import funkin.play.notes.NoteDirection;
import nx.NXMain;
import nx.controls.NXControlButton;

/**
 * Converts Switch D-pad and face-button transitions into the same precise
 * press/release signals consumed by the official note judgement system.
 *
 * Gameplay defaults:
 *   Y / D-pad Left  -> Left
 *   B / D-pad Down  -> Down
 *   X / D-pad Up    -> Up
 *   A / D-pad Right -> Right
 */
class NXPreciseInputHandler
{
  public var onButtonPressed:Null<(NoteDirection, Int64, Int) -> Void> = null;
  public var onButtonReleased:Null<(NoteDirection, Int64, Int) -> Void> = null;

  private var _previous:Map<NXControlButton, Bool> = [];

  public function new() {}

  public function update():Void
  {
    final controller = NXMain.nxController;
    if (controller == null) return;

    final timestamp = PreciseInputManager.getCurrentTimestamp();

    check(controller, NXControlButton.LEFT, NoteDirection.LEFT, timestamp, 0);
    check(controller, NXControlButton.DOWN, NoteDirection.DOWN, timestamp, 1);
    check(controller, NXControlButton.UP, NoteDirection.UP, timestamp, 2);
    check(controller, NXControlButton.RIGHT, NoteDirection.RIGHT, timestamp, 3);
    check(controller, NXControlButton.Y, NoteDirection.LEFT, timestamp, 4);
    check(controller, NXControlButton.B, NoteDirection.DOWN, timestamp, 5);
    check(controller, NXControlButton.X, NoteDirection.UP, timestamp, 6);
    check(controller, NXControlButton.A, NoteDirection.RIGHT, timestamp, 7);
  }

  private function check(
    controller:NXController,
    button:NXControlButton,
    direction:NoteDirection,
    timestamp:Int64,
    buttonCode:Int
  ):Void
  {
    final wasPressed = _previous.exists(button) && _previous.get(button);
    final isPressed = controller.isPressed(button);

    if (isPressed && !wasPressed)
    {
      onButtonPressed?.(direction, timestamp, buttonCode);
    }
    else if (!isPressed && wasPressed)
    {
      onButtonReleased?.(direction, timestamp, buttonCode);
    }

    _previous.set(button, isPressed);
  }

  public function destroy():Void
  {
    onButtonPressed = null;
    onButtonReleased = null;
    _previous.clear();
  }
}
#end

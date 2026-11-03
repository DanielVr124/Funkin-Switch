package nx;

import nx.controls.NXController;
import funkin.input.PreciseInputManager;

/**
 * Small lifecycle bridge for libnx services used by the Switch build.
 *
 * The regular Windows build never imports or initializes this class.
 */
class NXMain
{
  public static var nxController(default, null):Null<NXController>;

  public static function init():Void
  {
    #if switch
    if (nxController == null)
    {
      nxController = new NXController();
    }
    #end
  }

  /**
   * Poll hardware input once per frame. NXGame calls this before Flixel's
   * update so the current controller state is visible to the whole frame.
   */
  public static function update():Void
  {
    #if switch
    nxController?.update();

    // The getter creates the manager on first access. By the time NXGame
    // starts updating, OpenFL has created the application stage.
    PreciseInputManager.instance?.updateNXInput();
    #end
  }

  public static function destroy():Void
  {
    #if switch
    nxController?.destroy();
    nxController = null;
    #end
  }
}

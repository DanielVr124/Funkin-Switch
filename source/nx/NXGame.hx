package nx;

import flixel.FlxGame;
import flixel.FlxState;

/**
 * Flixel game loop wrapper for Nintendo Switch homebrew.
 *
 * The Switch controller poll must run once per frame before Flixel updates
 * gameplay and menu states.
 */
class NXGame extends FlxGame
{
  public function new(
    gameWidth:Int = 0,
    gameHeight:Int = 0,
    ?initialState:Class<FlxState>,
    updateFramerate:Int = 60,
    drawFramerate:Int = 60,
    skipSplash:Bool = false,
    startFullscreen:Bool = false
  )
  {
    super(gameWidth, gameHeight, initialState, updateFramerate, drawFramerate, skipSplash, startFullscreen);
  }

  override public function update():Void
  {
    NXMain.update();
    super.update();
  }
}

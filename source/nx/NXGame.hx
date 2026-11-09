package nx;

import flixel.FlxGame;
import flixel.FlxState;

class NXGame extends FlxGame {
    public function new(gameWidth:Int = 0, gameHeight:Int = 0, ?initialState:Class<FlxState>, zoom:Float = 1, ?updateFramerate:Int, ?drawFramerate:Int, skipSplash:Bool = false, startFullscreen:Bool = false) {
        super(gameWidth, gameHeight, initialState, updateFramerate, drawFramerate, skipSplash, startFullscreen);
    }

    override public function update(elapsed:Float):Void {
        NXMain.update();
        super.update(elapsed);
    }
}

package funkin.audio;

import flixel.FlxG;
import flixel.sound.FlxSound;
import funkin.play.PlayState;

/**
 * Passive Switch music watchdog for menus and non-gameplay states.
 *
 * Do not tear down or recreate the native audio device from a frame callback.
 * Native OpenAL shutdown can block the main thread if the driver has stalled.
 * Gameplay has its own channel-only recovery and audio-interrupted pause path.
 */
class SwitchAudioRecovery
{
  #if switch
  static final AUDIO_STALL_GRACE_PERIOD:Float = 1.25;
  static final AUDIO_POSITION_EPSILON_MS:Float = 1.0;

  static var monitoredMusic:Null<FlxSound> = null;
  static var musicWasExpected:Bool = false;
  static var lastMusicPosition:Float = -1.0;
  static var noProgressTimer:Float = 0.0;
  static var stallReported:Bool = false;

  /**
   * Called after every frame from Main. This is diagnostic only: it never
   * stops sounds, clears native buffers, or calls AudioManager.shutdown/init.
   */
  public static function update():Void
  {
    if (FlxG.state == null || Std.isOfType(FlxG.state, PlayState))
    {
      resetMonitor();
      return;
    }

    final music = FlxG.sound.music;
    if (music == null || !music.looped)
    {
      resetMonitor();
      return;
    }

    if (music != monitoredMusic)
    {
      monitoredMusic = music;
      musicWasExpected = music.exists && music.looped;
      lastMusicPosition = music.time;
      noProgressTimer = 0;
      stallReported = false;
    }

    if (!musicWasExpected && music.playing)
    {
      musicWasExpected = true;
      lastMusicPosition = music.time;
      noProgressTimer = 0;
      stallReported = false;
      return;
    }

    if (!musicWasExpected) return;

    if (music.playing
      && (lastMusicPosition < 0
        || Math.abs(music.time - lastMusicPosition) >= AUDIO_POSITION_EPSILON_MS))
    {
      lastMusicPosition = music.time;
      noProgressTimer = 0;
      stallReported = false;
      return;
    }

    // A pause caused by focus loss is intentional and must not trigger recovery.
    if (Std.isOfType(music, FunkinSound) && (cast music:FunkinSound).paused)
    {
      lastMusicPosition = music.time;
      noProgressTimer = 0;
      stallReported = false;
      return;
    }

    noProgressTimer += Math.max(0, FlxG.elapsed);
    if (noProgressTimer < AUDIO_STALL_GRACE_PERIOD || stallReported) return;

    // Rebuild only this looping source. Do not tear down the shared OpenAL
    // device from the frame loop: that path can block the Switch main thread.
    stallReported = true;
    final resumePosition:Float = Math.max(0.0, lastMusicPosition);
    trace('SWITCH AUDIO: Looping menu music stalled. Recreating its source at ${resumePosition}ms.');
    music.play(true, resumePosition);
    lastMusicPosition = resumePosition;
    noProgressTimer = 0;
  }

  static function resetMonitor():Void
  {
    monitoredMusic = null;
    musicWasExpected = false;
    lastMusicPosition = -1.0;
    noProgressTimer = 0;
    stallReported = false;
  }
  #end
}

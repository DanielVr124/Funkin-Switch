package nx.controls;

#if switch
import cpp.Pointer;
import switchLib.runtime.Pad.Pad;
import switchLib.runtime.Pad.PadState;
import switchLib.services.Hid.HidNpadButton;
import switchLib.services.Hid.HidNpadStyleTag;
#end

/**
 * Minimal controller poller backed by libnx. The Lime-NX SDL gamepad layer
 * remains responsible for ordinary menu navigation and analog axes; this
 * class supplies explicit button edges for rhythm-game timing.
 */
class NXController
{
  public static var instance(default, null):Null<NXController>;

  #if switch
  private var _pad:PadState;
  #end

  private var _buttonsHeld:Int = 0;
  private var _buttonsDown:Int = 0;
  private var _buttonsUp:Int = 0;

  public function new()
  {
    #if switch
    instance = this;

    // NpadStandard accepts handheld controls, paired Joy-Cons and Pro pads.
    Pad.padConfigureInput(1, HidNpadStyleTag.HidNpadStyleSet_NpadStandard);
    _pad = new PadState();
    Pad.padInitializeDefault(Pointer.addressOf(_pad));
    #end
  }

  /** Poll libnx. Must be called once every frame. */
  public function update():Void
  {
    #if switch
    final padPointer = Pointer.addressOf(_pad);
    Pad.padUpdate(padPointer);
    _buttonsDown = Pad.padGetButtonsDown(padPointer).toInt();
    _buttonsHeld = Pad.padGetButtons(padPointer).toInt();
    _buttonsUp = Pad.padGetButtonsUp(padPointer).toInt();
    #end
  }

  public function isPressed(button:NXControlButton):Bool
  {
    #if switch
    return (_buttonsHeld & getHidButton(button)) != 0;
    #else
    return false;
    #end
  }

  public function isJustPressed(button:NXControlButton):Bool
  {
    #if switch
    return (_buttonsDown & getHidButton(button)) != 0;
    #else
    return false;
    #end
  }

  public function isJustReleased(button:NXControlButton):Bool
  {
    #if switch
    return (_buttonsUp & getHidButton(button)) != 0;
    #else
    return false;
    #end
  }

  public function destroy():Void
  {
    if (instance == this) instance = null;
  }

  #if switch
  private static function getHidButton(button:NXControlButton):Int
  {
    return switch (button)
    {
      case A: HidNpadButton.HidNpadButton_A;
      case B: HidNpadButton.HidNpadButton_B;
      case X: HidNpadButton.HidNpadButton_X;
      case Y: HidNpadButton.HidNpadButton_Y;
      case STICK_L: HidNpadButton.HidNpadButton_StickL;
      case STICK_R: HidNpadButton.HidNpadButton_StickR;
      case L: HidNpadButton.HidNpadButton_L;
      case R: HidNpadButton.HidNpadButton_R;
      case ZL: HidNpadButton.HidNpadButton_ZL;
      case ZR: HidNpadButton.HidNpadButton_ZR;
      case PLUS: HidNpadButton.HidNpadButton_Plus;
      case MINUS: HidNpadButton.HidNpadButton_Minus;
      case LEFT: HidNpadButton.HidNpadButton_Left;
      case UP: HidNpadButton.HidNpadButton_Up;
      case RIGHT: HidNpadButton.HidNpadButton_Right;
      case DOWN: HidNpadButton.HidNpadButton_Down;
      case STICK_L_LEFT: HidNpadButton.HidNpadButton_StickLLeft;
      case STICK_L_UP: HidNpadButton.HidNpadButton_StickLUp;
      case STICK_L_RIGHT: HidNpadButton.HidNpadButton_StickLRight;
      case STICK_L_DOWN: HidNpadButton.HidNpadButton_StickLDown;
      case STICK_R_LEFT: HidNpadButton.HidNpadButton_StickRLeft;
      case STICK_R_UP: HidNpadButton.HidNpadButton_StickRUp;
      case STICK_R_RIGHT: HidNpadButton.HidNpadButton_StickRRight;
      case STICK_R_DOWN: HidNpadButton.HidNpadButton_StickRDown;
      case LEFT_SL: HidNpadButton.HidNpadButton_LeftSL;
      case LEFT_SR: HidNpadButton.HidNpadButton_LeftSR;
      case RIGHT_SL: HidNpadButton.HidNpadButton_RightSL;
      case RIGHT_SR: HidNpadButton.HidNpadButton_RightSR;
      case PALMA: HidNpadButton.HidNpadButton_Palma;
      case VERIFICATION: HidNpadButton.HidNpadButton_Verification;
      case HANDHELD_LEFT_B: HidNpadButton.HidNpadButton_HandheldLeftB;
      case LAGON_C_LEFT: HidNpadButton.HidNpadButton_LagonCLeft;
      case LAGON_C_UP: HidNpadButton.HidNpadButton_LagonCUp;
      case LAGON_C_RIGHT: HidNpadButton.HidNpadButton_LagonCRight;
      case LAGON_C_DOWN: HidNpadButton.HidNpadButton_LagonCDown;
      case ANY_LEFT: HidNpadButton.HidNpadButton_AnyLeft;
      case ANY_UP: HidNpadButton.HidNpadButton_AnyUp;
      case ANY_RIGHT: HidNpadButton.HidNpadButton_AnyRight;
      case ANY_DOWN: HidNpadButton.HidNpadButton_AnyDown;
      case ANY_SL: HidNpadButton.HidNpadButton_AnySL;
      case ANY_SR: HidNpadButton.HidNpadButton_AnySR;
    }
  }
  #end
}

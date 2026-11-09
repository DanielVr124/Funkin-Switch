package funkin.ui.options;

#if switch
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.text.FlxText.FlxTextAlign;
import flixel.util.FlxColor;
import funkin.ui.Page;
import nx.NXMain;
import nx.controls.NXControlButton.NXControlButton;

/**
 * Live Nintendo Switch controller input monitor.
 * Reads the same NXController state used by the game's precise note-input handler.
 */
class SwitchControllerTestMenu extends Page<OptionsState.OptionsMenuPageName>
{
  var readouts:Array<{button:NXControlButton, label:String, text:FlxText}> = [];
  var stickReadout:FlxText;
  var connectionReadout:FlxText;

  public function new()
  {
    super();

    var title = new FlxText(0, 55, FlxG.width, 'CONTROLLER TEST', 42);
    title.setFormat(Paths.font('vcr.ttf'), 42, FlxColor.WHITE, FlxTextAlign.CENTER);
    add(title);

    var instructions = new FlxText(80, 125, FlxG.width - 160, 'Press any controller button to see its indicator light up.\nPress BACK to return.', 26);
    instructions.setFormat(Paths.font('vcr.ttf'), 26, FlxColor.WHITE, FlxTextAlign.CENTER);
    add(instructions);

    connectionReadout = new FlxText(80, 190, FlxG.width - 160, 'CONTROLLER STATUS: CHECKING', 28);
    connectionReadout.setFormat(Paths.font('vcr.ttf'), 28, FlxColor.WHITE, FlxTextAlign.CENTER);
    add(connectionReadout);

    var buttons:Array<{button:NXControlButton, label:String}> = [
      {button: A, label: 'A'},
      {button: B, label: 'B'},
      {button: X, label: 'X'},
      {button: Y, label: 'Y'},
      {button: UP, label: 'D-PAD UP'},
      {button: DOWN, label: 'D-PAD DOWN'},
      {button: LEFT, label: 'D-PAD LEFT'},
      {button: RIGHT, label: 'D-PAD RIGHT'},
      {button: L, label: 'L'},
      {button: R, label: 'R'},
      {button: ZL, label: 'ZL'},
      {button: ZR, label: 'ZR'},
      {button: PLUS, label: '+'},
      {button: MINUS, label: '-'}
    ];

    for (i in 0...buttons.length)
    {
      var column = i % 4;
      var row = Std.int(i / 4);
      var x = 100 + column * 275;
      var y = 250 + row * 92;
      var label = new FlxText(x, y, 250, '${buttons[i].label}: RELEASED', 28);
      label.setFormat(Paths.font('vcr.ttf'), 28, FlxColor.WHITE, FlxTextAlign.CENTER);
      add(label);
      readouts.push({
        button: buttons[i].button,
        label: buttons[i].label,
        text: label
      });
    }

    stickReadout = new FlxText(80, 600, FlxG.width - 160, '', 22);
    stickReadout.setFormat(Paths.font('vcr.ttf'), 22, FlxColor.WHITE, FlxTextAlign.CENTER);
    add(stickReadout);
  }

  override function updateEnabled(elapsed:Float):Void
  {
    var controller = NXMain.nxController;

    final connected:Bool = controller != null && controller.isConnected;
    connectionReadout.text = connected ? 'CONTROLLER STATUS: CONNECTED' : 'CONTROLLER STATUS: DISCONNECTED / INCOMPLETE';
    connectionReadout.color = connected ? FlxColor.LIME : FlxColor.RED;

    for (readout in readouts)
    {
      var pressed:Bool = connected && controller.isPressed(readout.button);
      readout.text.text = '${readout.label}: ${pressed ? "PRESSED" : "RELEASED"}';
      readout.text.color = pressed ? FlxColor.LIME : FlxColor.WHITE;
    }

    if (controller != null)
    {
      var left = controller.getStickL();
      var right = controller.getStickR();
      stickReadout.text = 'LEFT STICK  X: ${formatAxis(left.x)}  Y: ${formatAxis(left.y)}'
        + '        RIGHT STICK  X: ${formatAxis(right.x)}  Y: ${formatAxis(right.y)}';
    }
    else
    {
      stickReadout.text = 'Switch controller input is unavailable.';
    }

    super.updateEnabled(elapsed);
  }

  static function formatAxis(value:Float):String
  {
    return Std.string(Math.round(value * 100) / 100);
  }
}
#end

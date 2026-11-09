package funkin.ui.options;

#if switch
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.Preferences;
import funkin.graphics.FunkinCamera;
import funkin.graphics.FunkinSprite;
import funkin.ui.AtlasText.AtlasFont;
import funkin.ui.Page;
import funkin.ui.TextMenuList;
import funkin.ui.TextMenuList.TextMenuItem;
import funkin.ui.options.items.CheckboxPreferenceItem;
import funkin.ui.options.items.EnumPreferenceItem;
import funkin.ui.options.items.NumberPreferenceItem;
import funkin.util.HapticUtil;
import funkin.util.HapticUtil.HapticsMode;

/**
 * Nintendo Switch-only settings. General preferences remain in PreferencesMenu;
 * this page contains controls and comfort options that are especially relevant
 * to the Switch port.
 */
class SwitchSettingsMenu extends Page<OptionsState.OptionsMenuPageName>
{
  var items:TextMenuList;
  var preferenceItems:FlxTypedSpriteGroup<FlxSprite>;
  var preferenceDesc:Array<String> = [];
  var itemDesc:FlxText;
  var itemDescBox:FunkinSprite;
  var menuCamera:FlxCamera;
  var hudCamera:FlxCamera;
  var camFollow:FlxObject;

  public function new()
  {
    super();

    menuCamera = new FunkinCamera('switchSettingsMenu');
    FlxG.cameras.add(menuCamera, false);
    menuCamera.bgColor = 0x0;

    hudCamera = new FlxCamera();
    FlxG.cameras.add(hudCamera, false);
    hudCamera.bgColor = 0x0;

    camera = menuCamera;

    add(items = new TextMenuList());
    add(preferenceItems = new FlxTypedSpriteGroup<FlxSprite>());

    add(itemDescBox = new FunkinSprite());
    itemDescBox.cameras = [hudCamera];

    add(itemDesc = new FlxText(0, 0, 1180, null, 32));
    itemDesc.cameras = [hudCamera];

    createPrefItems();
    createPrefDescription();

    camFollow = new FlxObject(FlxG.width / 2, 0, 140, 70);
    menuCamera.follow(camFollow, null, 0.085);
    var margin = 160;
    menuCamera.deadzone.set(0, margin, menuCamera.width, menuCamera.height - margin * 2);
    menuCamera.minScrollY = 0;

    items.onChange.add(function(selected)
    {
      itemDesc.text = preferenceDesc[items.selectedIndex];
    });
  }

  function createPrefItems():Void
  {
    createPrefItemCheckbox('Auto-Pause on Disconnect', 'Pause the song automatically if your controller or one side of a paired Joy-Con disconnects. The song resumes after a stable reconnection.', function(value:Bool):Void
    {
      Preferences.switchAutoPauseOnDisconnect = value;
    }, Preferences.switchAutoPauseOnDisconnect);

    createPrefItemCheckbox('Touchscreen Controls', 'Show the original FNF on-screen note controls during gameplay. Physical Joy-Con/controller input remains available at the same time.', function(value:Bool):Void
    {
      Preferences.switchTouchControlsEnabled = value;
    }, Preferences.switchTouchControlsEnabled);

    var touchLayoutLabel:String = switch (Preferences.switchTouchControlsScheme)
    {
      case 'Four Lanes': 'Four Lanes';
      case 'Double Thumb Triangle': 'Double Thumb Triangle';
      case 'Double Thumb Square': 'Double Thumb Square';
      case 'Double Thumb DPad': 'Double Thumb DPad';
      default: 'Arrows (Default)';
    };

    createPrefItemEnum('Touch Control Layout', 'Choose the original FNF touchscreen button arrangement. This setting is saved separately from the physical Switch controller layout.', [
      'Arrows (Default)' => 'Arrows',
      'Four Lanes' => 'Four Lanes',
      'Double Thumb Triangle' => 'Double Thumb Triangle',
      'Double Thumb Square' => 'Double Thumb Square',
      'Double Thumb DPad' => 'Double Thumb DPad'
    ], function(key:String, value:String):Void
    {
      Preferences.switchTouchControlsScheme = value;
    }, touchLayoutLabel);

    var layoutLabel:String = switch (Preferences.switchNoteInputLayout)
    {
      case 'DPad': 'D-Pad Only';
      case 'FaceButtons': 'Face Buttons';
      case 'Shoulders': 'Shoulder Buttons';
      default: 'Hybrid (Default)';
    };

    createPrefItemEnum('Note Input Layout', 'Choose which physical buttons control notes. Shoulder Buttons uses L, R, ZL, and ZR to reduce repeated face-button presses.', [
      'Hybrid (Default)' => 'Hybrid',
      'D-Pad Only' => 'DPad',
      'Face Buttons' => 'FaceButtons',
      'Shoulder Buttons' => 'Shoulders'
    ], function(key:String, value:String):Void
    {
      Preferences.switchNoteInputLayout = value;
    }, layoutLabel);

    createActionItem('Controller Test', 'Open a live button tester. Press a controller button and its indicator will light up.', function()
    {
      codex.switchPage(SwitchControllerTest);
    });

    createPrefItemCheckbox('Flashing Effects', 'When disabled, flashing effects are reduced. This can make gameplay more comfortable.', function(value:Bool):Void
    {
      Preferences.flashingLights = value;
    }, Preferences.flashingLights);

    createPrefItemCheckbox('Camera Zooms', 'When disabled, beat-synced camera bumps are turned off to reduce screen movement.', function(value:Bool):Void
    {
      Preferences.zoomCamera = value;
    }, Preferences.zoomCamera);

    #if FEATURE_HAPTICS
    createPrefItemEnum('HD Rumble', 'Choose when the Joy-Con HD Rumble is used.', [
      'All' => HapticsMode.ALL,
      'Notes Only' => HapticsMode.NOTES_ONLY,
      'Off' => HapticsMode.NONE
    ], function(key:String, value:HapticsMode):Void
    {
      Preferences.hapticsMode = value;
    }, switch (Preferences.hapticsMode)
      {
        case HapticsMode.NOTES_ONLY: 'Notes Only';
        case HapticsMode.NONE: 'Off';
        default: 'All';
      });

    createPrefItemNumber('Rumble Intensity', 'Adjust the strength of HD Rumble effects.', function(value:Float):Void
    {
      Preferences.hapticsIntensityMultiplier = value;
    }, null, Preferences.hapticsIntensityMultiplier, 0.1, 5, 0.1, 1);

    createActionItem('Test Rumble', 'Play a short rumble using the current HD Rumble settings. Set HD Rumble to All to test it.', function()
    {
      HapticUtil.vibrate(0, 0.25, 0.3, 0.65, [HapticsMode.ALL]);
    });
    #end
  }

  function createPrefDescription():Void
  {
    itemDescBox.makeSolidColor(1, 1, FlxColor.BLACK);
    itemDescBox.alpha = 0.6;
    itemDesc.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    itemDesc.borderSize = 3;

    itemDesc.text = preferenceDesc[items.selectedIndex];
    itemDesc.screenCenter();
    itemDesc.y += 270;

    itemDescBox.setPosition(itemDesc.x - 10, itemDesc.y - 10);
    itemDescBox.setGraphicSize(Std.int(itemDesc.width + 20), Std.int(itemDesc.height + 25));
    itemDescBox.updateHitbox();
  }

  function createActionItem(name:String, description:String, callback:Void->Void):Void
  {
    var item = items.createItem(0, (120 * items.length) + 30, name, AtlasFont.BOLD, callback);
    item.screenCenter(X);
    preferenceDesc.push(description);
  }

  function createPrefItemCheckbox(prefName:String, prefDesc:String, onChange:Bool->Void, defaultValue:Bool):Void
  {
    var checkbox = new CheckboxPreferenceItem(funkin.ui.FullScreenScaleMode.gameNotchSize.x, 120 * items.length, defaultValue);

    items.createItem(0, (120 * items.length) + 30, prefName, AtlasFont.BOLD, function()
    {
      var value = !checkbox.currentValue;
      onChange(value);
      checkbox.currentValue = value;
    });

    preferenceItems.add(checkbox);
    preferenceDesc.push(prefDesc);
  }

  function createPrefItemNumber(prefName:String, prefDesc:String, onChange:Float->Void, ?valueFormatter:Float->String, defaultValue:Float,
      min:Float, max:Float, step:Float = 0.1, precision:Int):Void
  {
    var item = new NumberPreferenceItem(funkin.ui.FullScreenScaleMode.gameNotchSize.x, (120 * items.length) + 30, prefName, defaultValue, min, max, step,
      precision, onChange, valueFormatter);
    items.addItem(prefName, item);
    preferenceItems.add(item.lefthandText);
    preferenceDesc.push(prefDesc);
  }

  function createPrefItemEnum<T>(prefName:String, prefDesc:String, values:Map<String, T>, onChange:String->T->Void, defaultKey:String):Void
  {
    var item = new EnumPreferenceItem<T>(funkin.ui.FullScreenScaleMode.gameNotchSize.x, (120 * items.length) + 30, prefName, values, defaultKey, onChange);
    items.addItem(prefName, item);
    preferenceItems.add(item.lefthandText);
    preferenceDesc.push(prefDesc);
  }

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);
    if (items != null && items.selectedItem != null) camFollow.y = items.selectedItem.y;

    items.forEach(function(daItem:TextMenuItem)
    {
      var thyOffset:Int = 0;

      switch (Type.typeof(daItem))
      {
        case TClass(CheckboxPreferenceItem):
          thyOffset = 0;
        case TClass(EnumPreferenceItem):
          thyOffset = cast(daItem, EnumPreferenceItem<Dynamic>).lefthandText.getWidth() - 75;
        case TClass(NumberPreferenceItem):
          thyOffset = cast(daItem, NumberPreferenceItem).lefthandText.getWidth() - 75;
        default:
          // Action rows use the same left-column alignment as the other options.
      }

      thyOffset += (items.selectedItem == daItem) ? 150 : 120;
      daItem.x = thyOffset + funkin.ui.FullScreenScaleMode.gameNotchSize.x;
    });
  }

  override function exit():Void
  {
    camFollow.setPosition(640, 30);
    menuCamera.snapToTarget();
    super.exit();
  }
}
#end

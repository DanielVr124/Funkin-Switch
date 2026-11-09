package nx.controls;

import haxe.Json;
import nx.controls.NXControlButton.NXJoyCon;

#if switch
import cpp.RawPointer;
import cpp.Pointer;
import sys.FileSystem;
import sys.io.File;
import switchLib.services.Hid;
#end

/**
 * A struct for holding vibration data
 */
typedef NXVibrationData = {
    var joycon:NXJoyCon;
    var duration:Float;
    var amplitude_low:Float;
    var frequency_low:Float;
    var amplitude_high:Float;
    var frequency_high:Float;
}

/**
 * Raw JSON vibration data structure
 */
typedef NXVibrationDataJson = {
    var joycon:Int;
    var duration:Float;
    var amplitude_low:Float;
    var frequency_low:Float;
    var amplitude_high:Float;
    var frequency_high:Float;
    var waitForNext:Float;
}

/**
 * JSON structure for vibration sequences
 */
typedef NXVibrationSequence = {
    var data:Array<NXVibrationDataJson>;
}

/**
 * A class for handling Joy-Con vibrations
 *
 * Ported from Vupx Engine
 *
 * Author: Slushi
 */
class NXVibrationHD {
    public var isRunning:Bool = false;

    #if switch
    private var handlesPtr:RawPointer<HidVibrationDeviceHandle>;
    private var vibrationData:HidVibrationValue;
    private var currentMode:Int = 0;
    private var sequenceRunning:Bool = false;

    private var stopValue:HidVibrationValue;
    private var bothValues:Array<HidVibrationValue>;

    private var leftTimer:Float = 0;
    private var rightTimer:Float = 0;

    private var _sequenceSteps:Array<NXVibrationDataJson> = null;
    private var _currentStepIndex:Int = 0;
    private var _sequenceWaitTimer:Float = 0;
    #end

    public function new() {
        #if switch
        handlesPtr = untyped __cpp__("(HidVibrationDeviceHandle*)malloc(4 * sizeof(HidVibrationDeviceHandle))");

        Hid.hidInitializeVibrationDevices(
            handlesPtr,
            2,
            HidNpadIdType.HidNpadIdType_Handheld,
            HidNpadStyleTag.HidNpadStyleTag_NpadHandheld
        );

        var dockedPtr:RawPointer<HidVibrationDeviceHandle> = untyped __cpp__("{0} + 2", handlesPtr);
        Hid.hidInitializeVibrationDevices(
            dockedPtr,
            2,
            HidNpadIdType.HidNpadIdType_No1,
            HidNpadStyleTag.HidNpadStyleTag_NpadJoyDual
        );

        vibrationData = new HidVibrationValue();

        stopValue = new HidVibrationValue();
        stopValue.amp_low = 0;
        stopValue.amp_high = 0;
        stopValue.freq_low = 160.0;
        stopValue.freq_high = 320.0;

        bothValues = [new HidVibrationValue(), new HidVibrationValue()];
        #end
    }

    /**
     * Updates internal timers for vibration durations and sequences.
     * MUST be called every frame in the main loop.
     */
    public function update(elapsed:Float):Void {
        #if switch
        // Handle Left Joy-Con auto-stop
        if (leftTimer > 0) {
            leftTimer -= elapsed;
            if (leftTimer <= 0) {
                leftTimer = 0;
                _sendStopDirect(NXJoyCon.LEFT);
            }
        }

        // Handle Right Joy-Con auto-stop
        if (rightTimer > 0) {
            rightTimer -= elapsed;
            if (rightTimer <= 0) {
                rightTimer = 0;
                _sendStopDirect(NXJoyCon.RIGHT);
            }
        }

        if (sequenceRunning && _sequenceSteps != null) {
            _sequenceWaitTimer -= elapsed;

            if (_sequenceWaitTimer <= 0) {
                if (_currentStepIndex < _sequenceSteps.length) {
                    var step = _sequenceSteps[_currentStepIndex];
                    var joy:NXJoyCon = (step.joycon == 0) ? NXJoyCon.LEFT : NXJoyCon.RIGHT;

                    _internalVibrate(joy, step.amplitude_low, step.frequency_low, step.amplitude_high, step.frequency_high);

                    if (joy == NXJoyCon.LEFT) leftTimer = step.duration;
                    else rightTimer = step.duration;

                    _sequenceWaitTimer = step.duration + step.waitForNext;
                    _currentStepIndex++;
                } else {
                    sequenceRunning = false;
                    _sequenceSteps = null;
                }
            }
        }

        isRunning = (leftTimer > 0 || rightTimer > 0 || sequenceRunning);
        #end
    }

    #if switch
    private inline function getHandle(joycon:NXJoyCon):HidVibrationDeviceHandle {
        var joyconIndex = (joycon == NXJoyCon.LEFT) ? 0 : 1;
        var index = currentMode * 2 + joyconIndex;
        return handlesPtr[index];
    }

    private inline function getHandlePtr(joycon:NXJoyCon):RawPointer<HidVibrationDeviceHandle> {
        var joyconIndex = (joycon == NXJoyCon.LEFT) ? 0 : 1;
        var index = currentMode * 2 + joyconIndex;
        return untyped __cpp__("{0} + {1}", handlesPtr, index);
    }
    #end

    /**
     * Switch between handheld and docked mode
     * @param isHandheld
     */
    public function updateMode(isHandheld:Bool) {
        #if switch
        currentMode = isHandheld ? 0 : 1;
        #end
    }

    /**
     * Vibrate a single Joy-Con
     * @param data Vibration parameters
     */
    public function vibrate(data:NXVibrationData) {
        #if switch
        _internalVibrate(data.joycon, data.amplitude_low, data.frequency_low, data.amplitude_high, data.frequency_high);

        if (data.duration > 0) {
            if (data.joycon == NXJoyCon.LEFT) leftTimer = data.duration;
            else rightTimer = data.duration;
        }
        #end
    }

    /**
     * Stop vibration on a single Joy-Con
     * @param joycon Which Joy-Con to stop
     */
    public function stop(joycon:NXJoyCon) {
        #if switch
        if (joycon == NXJoyCon.LEFT) leftTimer = 0;
        else rightTimer = 0;

        _sendStopDirect(joycon);
        #end
    }

    /**
     * Vibrate both Joy-Cons with the same parameters
     * @param data Vibration parameters
     */
    public function vibrateBoth(data:NXVibrationData) {
        #if switch
        var values:Array<HidVibrationValue> = [
            createVibrationValue(data),
            createVibrationValue(data)
        ];

        var baseHandlePtr:RawPointer<HidVibrationDeviceHandle> = untyped __cpp__("{0} + {1}", handlesPtr, currentMode * 2);

        Hid.hidSendVibrationValues(
            baseHandlePtr,
            Pointer.arrayElem(values, 0),
            2
        );

        if (data.duration > 0) {
            leftTimer = data.duration;
            rightTimer = data.duration;
        }
        #end
    }

    /**
     * Load and play a vibration sequence from a JSON file
     * @param jsonPath Path to the JSON file
     * @return Bool True if loaded successfully
     */
    public function loadSequenceFromJson(jsonPath:String):Bool {
        #if (switch && sys)
        if (!FileSystem.exists(jsonPath)) {
            trace("Vibration file not found: " + jsonPath);
            return false;
        }

        try {
            var jsonContent = File.getContent(jsonPath);
            var sequence:NXVibrationSequence = Json.parse(jsonContent);
            playSequence(sequence.data);
            return true;
        } catch (e:Dynamic) {
            trace("Error loading vibration sequence: " + e);
            return false;
        }
        #else
        return false;
        #end
    }

    /**
     * Load and play a vibration sequence from a JSON string
     * @param jsonString JSON string containing vibration data
     * @return Bool True if loaded successfully
     */
    public function loadSequenceFromString(jsonString:String):Bool {
        #if switch
        try {
            var sequence:NXVibrationSequence = Json.parse(jsonString);
            playSequence(sequence.data);
            return true;
        } catch (e:Dynamic) {
            trace("Error parsing vibration sequence: " + e);
            return false;
        }
        #else
        return false;
        #end
    }

    /**
     * Play a sequence of vibrations
     * @param sequence Array of raw vibration data
     */
    private function playSequence(sequence:Array<NXVibrationDataJson>) {
        #if switch
        if (sequenceRunning) {
            trace("A vibration sequence is already running");
            return;
        }

        _sequenceSteps = sequence;
        _currentStepIndex = 0;
        _sequenceWaitTimer = 0;
        sequenceRunning = true;
        #end
    }

    /**
     * Stop the current vibration sequence
     */
    public function stopSequence() {
        #if switch
        sequenceRunning = false;
        _sequenceSteps = null;
        stop(NXJoyCon.LEFT);
        stop(NXJoyCon.RIGHT);
        #end
    }

    #if switch
    private function createVibrationValue(data:NXVibrationData):HidVibrationValue {
        var val = new HidVibrationValue();
        val.amp_low = data.amplitude_low;
        val.freq_low = data.frequency_low;
        val.amp_high = data.amplitude_high;
        val.freq_high = data.frequency_high;
        return val;
    }

    private function _internalVibrate(joy:NXJoyCon, al:Float, fl:Float, ah:Float, fh:Float) {
        vibrationData.amp_low = al;
        vibrationData.freq_low = fl;
        vibrationData.amp_high = ah;
        vibrationData.freq_high = fh;
        Hid.hidSendVibrationValue(getHandle(joy), Pointer.addressOf(vibrationData));
    }

    private function _sendStopDirect(joy:NXJoyCon) {
        Hid.hidSendVibrationValue(getHandle(joy), Pointer.addressOf(stopValue));
    }

    public function destroy() {
        untyped __cpp__("free({0})", handlesPtr);
    }
    #else
    public function destroy() {}
    #end
}

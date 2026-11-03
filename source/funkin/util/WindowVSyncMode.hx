package funkin.util;

/**
 * Platform-independent VSync preference values.
 *
 * The desktop Lime API exposes lime.ui.WindowVSyncMode, while the pinned
 * Lime-NX fork exposes lime.app.VSyncMode. Keep saved preferences and menu
 * code independent of either backend type; WindowUtil translates at runtime.
 */
enum abstract WindowVSyncMode(String) from String to String
{
  var OFF = "Off";
  var ON = "On";
  var ADAPTIVE = "Adaptive";
}

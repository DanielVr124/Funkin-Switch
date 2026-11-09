package nx;

#if switch
import switchLib.applets.Web;
import switchLib.applets.Web.WebCommonConfig;
import switchLib.Result;
import switchLib.Types.ResultType;
import cpp.Pointer;
#end

/**
 * TODO:
 * - Add support for Youtube embed videos
 */
/**
 * Class for start a simple web page applet
 *
 * Note: Youtube embed videos are not supported FOR NOW
 *
 * Ported from Vupx Engine
 *
 * Author: Slushi
 */
class NXSimpleWeb
{
  /**
   * The URL of the request
   */
  public var url:Null<String> = "";

  #if switch
  /**
   * The result of the request
   */
  private var result:Null<ResultType>;
  #end

  /**
   * Whether the request failed
   */
  private var failed:Bool = false;

  /**
   * Whether the request has been initialized
   */
  private var initialized:Bool = false;

  #if switch
  /**
   * The config of the request
   */
  @:unreflective
  private var webConfig:Null<WebCommonConfig>;
  #end

  /**
   * Creates a new web page applet with the specified URL
   * @param url The URL of the request
   */
  public function new(url:String)
  {
    #if switch
    if (NXMain.isRunningAsApplet())
    {
      trace("ERROR - NXSimpleWeb can't be used when is running as applet");
      failed = true;
      return;
    }

    if (url == "" || url == null)
    {
      trace("ERROR - The URL is null or empty");
      failed = true;
      return;
    }

    this.url = url;
    this.webConfig = new WebCommonConfig();
    this.result = Web.webPageCreate(Pointer.addressOf(this.webConfig), this.url);

    if (Result.R_SUCCEEDED(result))
    {
      trace("Successfully configured web page, starting request");

      result = Web.webConfigSetWhitelist(Pointer.addressOf(this.webConfig), "^http*");
      if (Result.R_FAILED(result))
      {
        trace("ERROR - Failed to set whitelist");
        failed = true;
        return;
      }
    }

    if (Result.R_FAILED(result))
    {
      trace("ERROR - Failed to configure web page");
      failed = true;
      return;
    }

    initialized = true;
    #end
  }

  /**
   * Shows the web page
   */
  public function showWebPage():Void
  {
    #if switch
    if (failed || !initialized || (failed && !initialized)) return;
    var result:ResultType = Web.webConfigShow(Pointer.addressOf(this.webConfig), null);
    if (Result.R_FAILED(result))
    {
      trace("ERROR - Failed to show web page: " + result);
      failed = true;
    }
    #end
  }

  public function destroy():Void
  {
    #if switch
    url = null;
    // webConfig = null; // compiler error
    result = null;
    #end
  }
}

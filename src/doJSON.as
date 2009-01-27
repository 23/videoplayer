
import com.adobe.net.DynamicURLLoader;
import com.adobe.serialization.json.JSON;
private function doJSON(url:String, f:Function):DynamicURLLoader {
   	var loader:DynamicURLLoader = new DynamicURLLoader();
	loader.addEventListener(Event.COMPLETE, function(e:Event):void {f(JSON.decode(loader.data));});
	loader.load(new URLRequest(url));
	return(loader);
}

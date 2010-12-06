
import com.adobe.net.DynamicURLLoader;
import com.adobe.serialization.json.JSON;
import com.adobe.serialization.json.JSONParseError;
private function doJSON(url:String, f:Function):DynamicURLLoader {
   	var loader:DynamicURLLoader = new DynamicURLLoader();
	loader.addEventListener(Event.COMPLETE, function(e:Event):void {f(JSON.decode(loader.data));});
	loader.load(new URLRequest(url));
	return(loader);
}
private function doAPI(method:String, parameters:Object, f:Function):DynamicURLLoader {
	parameters['raw'] = 't';
	parameters['format'] = 'json';
	var url:String = 'http://' + props.get('domain') + method + '?' + toQueryString(parameters); 
	return doJSON(url, f);
}
private function toQueryString(o:Object):String {
	var a:Array = [];
	for (var s:String in o) {
		a.push(encodeURIComponent(s) + '=' + encodeURIComponent(o[s]));
	}
	return(a.join('&'));
}
